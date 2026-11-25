#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils git openssh sops ssh-to-age wireguard-tools

# Enrolls a host's SSH host key as its sops identity: records the public key in
# hosts/<host>/ssh_host_ed25519_key.pub and re-encrypts the secrets for it. A
# new host also gets secrets/<host>.yaml, with a fresh home-VPN key pair.

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") -n <hostname> (-p <pubkey> | -s <ssh destination> | -g <dir>)"
  echo ""
  echo "  -n <hostname>         Host to enroll, matching a directory in './hosts'."
  echo "  -p <pubkey>           The host's public key file, e.g. /etc/ssh/ssh_host_ed25519_key.pub."
  echo "  -s <ssh destination>  Read it from a running host over SSH (checked against known_hosts)."
  echo "  -g <dir>              Generate a new host key pair into <dir>, for a new install."
  exit 1
}

hostname="" source=""
while getopts ":n:p:s:g:" opt; do
  case $opt in
    n) hostname="$OPTARG" ;;
    p | s | g)
      [[ -z "$source" ]] || usage
      source="$opt" arg="$OPTARG"
      ;;
    *) usage ;;
  esac
done
[[ -n "$hostname" && -n "$source" ]] || usage
cd "$REPO_DIR"
if [[ ! -d "hosts/$hostname" ]]; then
  echo "[❌] No host configuration at hosts/$hostname" >&2
  exit 1
fi

case $source in
  p) pub_key="$(<"$arg")" ;;
  s) pub_key="$(ssh "$arg" cat /etc/ssh/ssh_host_ed25519_key.pub)" ;;
  g)
    if [[ -e "$arg/ssh_host_ed25519_key" ]]; then
      echo "[❌] $arg/ssh_host_ed25519_key already exists; enroll it with -p" >&2
      exit 1
    fi
    mkdir -p "$arg"
    ssh-keygen -q -t ed25519 -N "" -C "root@$hostname" -f "$arg/ssh_host_ed25519_key"
    echo "[✔️] Generated a new host key at $arg/ssh_host_ed25519_key"
    pub_key="$(<"$arg/ssh_host_ed25519_key.pub")"
    ;;
esac

read -r key_type key_data _ <<<"$pub_key"
if [[ "$key_type" != "ssh-ed25519" ]] || ! ssh-keygen -l -f <(echo "$key_type $key_data") >/dev/null 2>&1; then
  echo "[❌] Not an ssh-ed25519 public key" >&2
  exit 1
fi

pub_file="hosts/$hostname/ssh_host_ed25519_key.pub"
if [[ -f "$pub_file" ]] && ! grep -qF "$key_data" "$pub_file"; then
  echo "[⚠️] Replacing the enrolled host key of '$hostname'"
fi
echo "$key_type $key_data root@$hostname" >"$pub_file"
echo "   └─ $(ssh-keygen -l -f "$pub_file" | cut -d' ' -f2) -> $(ssh-to-age <"$pub_file")"

scripts/update_sops.sh

host_secrets="secrets/$hostname.yaml"
if [[ ! -f "$host_secrets" ]]; then
  echo "Creating $host_secrets with a new home-VPN WireGuard key pair..."
  private_key="$(wg genkey)"
  # Public key first: if anything fails, $host_secrets doesn't exist and a
  # rerun generates a fresh, consistent pair
  printf '"%s"' "$(wg pubkey <<<"$private_key")" |
    sops set --value-stdin secrets/common.yaml "[\"wireguard\"][\"home_vpn\"][\"$hostname\"][\"public_key\"]"
  # Only through stdin (printf is a builtin): never in process listings
  printf 'wireguard:\n  home_vpn:\n    %s:\n      private_key: %s\n' "$hostname" "$private_key" |
    sops encrypt --filename-override "$host_secrets" >"$host_secrets.tmp"
  mv "$host_secrets.tmp" "$host_secrets"
  echo "[✔️] Created $host_secrets; add other secrets with: sops $host_secrets"
fi

git add .sops.yaml "$pub_file" secrets/*.yaml
echo "[✔️] Enrolled '$hostname'. Commit and push before deploying."
