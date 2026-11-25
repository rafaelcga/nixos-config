#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p nixos-install-tools coreutils git disko openssh

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$ROOT_DIR")"
ROOT_MNT="/mnt"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") -n <hostname> -k <host_key>"
  echo ""
  echo "Performs a local NixOS installation using a specified host configuration and disko for partitioning."
  echo ""
  echo "Options:"
  echo "  -n <hostname>   (Required) The hostname to install, corresponding to a configuration in the './hosts' directory."
  echo "  -k <host_key>   (Required) The host's SSH private host key, already enrolled for sops."
  echo ""
  echo "Enroll the key first on a machine that can edit the secrets, then pull that commit here:"
  echo "  scripts/enroll_host.sh -n <hostname> -g <dir on a USB drive>"
  exit 1
}

hostname=""
key_path=""
while getopts ":n:k:" opt; do
  case $opt in
    n) hostname="$OPTARG" ;;
    k) key_path="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$hostname" || ! -f "$key_path" ]]; then
  echo "Error: Missing hostname or host key file." >&2
  usage
fi

# The key must match the enrolled public key, or the system can't decrypt its secrets
enrolled_pub="$REPO_DIR/hosts/$hostname/ssh_host_ed25519_key.pub"
if [[ ! -f "$enrolled_pub" ]]; then
  echo "[❌] '$hostname' is not enrolled (no $enrolled_pub). See -h." >&2
  exit 1
fi
read -r _ key_data _ < <(ssh-keygen -y -f "$key_path")
read -r _ enrolled_data _ <"$enrolled_pub"
if [[ "$key_data" != "$enrolled_data" ]]; then
  echo "[❌] $key_path does not match the enrolled key in $enrolled_pub" >&2
  exit 1
fi

flake="$REPO_DIR#$hostname"

echo "--------------------------------------------------"
"$ROOT_DIR/generate_hardware.sh" -n "$hostname"

echo "--------------------------------------------------"
echo "Formatting disks..."
sudo disko --mode destroy,format,mount --root-mountpoint "$ROOT_MNT" --flake "$flake"

echo "--------------------------------------------------"
echo "Installing the SSH host key (the host's sops identity)..."
sudo install -D -m 600 -o root -g root "$key_path" "$ROOT_MNT/etc/ssh/ssh_host_ed25519_key"
sudo install -D -m 644 -o root -g root "$enrolled_pub" "$ROOT_MNT/etc/ssh/ssh_host_ed25519_key.pub"

echo "--------------------------------------------------"
echo "Performing NixOS install..."
sudo nixos-install --flake "$flake"
