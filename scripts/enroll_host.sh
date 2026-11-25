#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils git openssh sops ssh-to-age wireguard-tools

# Enrolls a host's SSH host key as its sops identity: records the public key in
# hosts/<host>/ssh_host_ed25519_key.pub, regenerates .sops.yaml, re-encrypts
# the secrets and, for a new host, creates secrets/<host>.yaml with a fresh
# home-VPN WireGuard key pair.

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") -n <hostname> (-p <pubkey> | -s <ssh destination> | -g <dir>)"
  echo ""
  echo "Enrolls a host's SSH ed25519 host key as its sops (age) identity."
  echo ""
  echo "Options:"
  echo "  -n <hostname>         (Required) Host to enroll, matching a directory in './hosts'."
  echo "  -p <pubkey>           Path to the host's public key, e.g. /etc/ssh/ssh_host_ed25519_key.pub"
  echo "                        when run on the host itself."
  echo "  -s <ssh destination>  Read the public key from a running host over SSH (verified"
  echo "                        against your known_hosts)."
  echo "  -g <dir>              Generate a new key pair into <dir> (for a new install) and"
  echo "                        enroll it. The private key never enters the repository."
  exit 1
}

hostname=""
pub_path=""
ssh_dest=""
gen_dir=""
while getopts ":n:p:s:g:" opt; do
  case $opt in
    n) hostname="$OPTARG" ;;
    p) pub_path="$OPTARG" ;;
    s) ssh_dest="$OPTARG" ;;
    g) gen_dir="$OPTARG" ;;
    *) usage ;;
  esac
done

sources=0
for source in "$pub_path" "$ssh_dest" "$gen_dir"; do [[ -n "$source" ]] && sources=$((sources + 1)); done
if [[ -z "$hostname" || $sources -ne 1 ]]; then
  echo "Error: A hostname and exactly one of -p, -s or -g are required." >&2
  usage
fi
if [[ ! -d "$REPO_DIR/hosts/$hostname" ]]; then
  echo "[❌] No host configuration at hosts/$hostname" >&2
  exit 1
fi

if [[ -n "$gen_dir" ]]; then
  key_path="$gen_dir/ssh_host_ed25519_key"
  if [[ -e "$key_path" ]]; then
    echo "[❌] $key_path already exists; use -p $key_path.pub to enroll it" >&2
    exit 1
  fi
  mkdir -p "$gen_dir"
  ssh-keygen -q -t ed25519 -N "" -C "root@$hostname" -f "$key_path"
  chmod 600 "$key_path"
  echo "[✔️] Generated a new host key at $key_path"
  pub_key="$(<"$key_path.pub")"
elif [[ -n "$ssh_dest" ]]; then
  pub_key="$(ssh "$ssh_dest" cat /etc/ssh/ssh_host_ed25519_key.pub)"
else
  pub_key="$(<"$pub_path")"
fi

# Keep only "<type> <key>", and check it really is an ed25519 public key
read -r key_type key_data _ <<<"$pub_key"
if [[ "$key_type" != "ssh-ed25519" ]] || ! ssh-keygen -l -f <(echo "$key_type $key_data") >/dev/null 2>&1; then
  echo "[❌] Not an ssh-ed25519 public key" >&2
  exit 1
fi
pub_key="$key_type $key_data root@$hostname"

pub_file="$REPO_DIR/hosts/$hostname/ssh_host_ed25519_key.pub"
if [[ -f "$pub_file" ]]; then
  read -r _ old_data _ <"$pub_file"
  if [[ "$old_data" == "$key_data" ]]; then
    echo "[✔️] Host key of '$hostname' already enrolled"
  else
    echo "[⚠️] Replacing the enrolled host key of '$hostname' (was $(ssh-keygen -l -f "$pub_file" | cut -d' ' -f2))"
  fi
fi
echo "$pub_key" >"$pub_file"
echo "   └─ $(ssh-keygen -l -f "$pub_file" | cut -d' ' -f1,2) -> $(ssh-to-age <"$pub_file")"

"$REPO_DIR/scripts/update_sops.sh"

cd "$REPO_DIR"
host_secrets="secrets/$hostname.yaml"
if [[ ! -f "$host_secrets" ]]; then
  if [[ ! -f secrets/common.yaml ]]; then
    echo "[⚠️] secrets/common.yaml does not exist yet; run scripts/split_secrets.sh"
  else
    echo "Creating $host_secrets with a new home-VPN WireGuard key pair..."
    private_key="$(wg genkey)"
    # Public key first: if anything fails, $host_secrets doesn't exist and a
    # rerun generates a fresh, consistent pair (overwriting the public key)
    printf '"%s"' "$(wg pubkey <<<"$private_key")" |
      sops set --value-stdin secrets/common.yaml "[\"wireguard\"][\"home_vpn\"][\"$hostname\"][\"public_key\"]"
    # Through stdin only (printf is a builtin), so the private key never shows
    # in process listings
    printf 'wireguard:\n  home_vpn:\n    %s:\n      private_key: %s\n' "$hostname" "$private_key" |
      sops encrypt --filename-override "$host_secrets" >"$host_secrets.tmp"
    mv "$host_secrets.tmp" "$host_secrets"
    unset private_key
    echo "[✔️] Created $host_secrets; add any other secrets it needs with: sops $host_secrets"
  fi
fi

git add .sops.yaml "$pub_file" secrets/*.yaml
echo "[✔️] Enrolled '$hostname'. Commit and push before deploying:"
echo "    git commit -m \"(sops) enroll $hostname\" && git push"
