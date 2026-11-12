#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p nixos-install-tools coreutils git disko

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$ROOT_DIR")"
ROOT_MNT="/mnt"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") -n <hostname> -k <ssh_key_path>"
  echo ""
  echo "Performs a local NixOS installation using a specified host configuration and disko for partitioning."
  echo ""
  echo "Options:"
  echo "  -n <hostname>        (Required) The hostname to install, corresponding to a configuration in the './hosts' directory."
  echo "  -k <ssh_key_path>    (Required) Path to the SSH private key for SOPS to access secrets during installation."
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
  echo "Error: Missing hostname or SSH key file." >&2
  usage
fi

flake="$REPO_DIR#$hostname"

echo "--------------------------------------------------"
"$ROOT_DIR/generate_hardware.sh" -n "$hostname"

echo "--------------------------------------------------"
echo "Formatting disks..."
sudo disko --mode destroy,format,mount --root-mountpoint "$ROOT_MNT" --flake "$flake"

echo "--------------------------------------------------"
echo "Copying SSH key for SOPS secrets..."
sudo install -D -m 600 -o root -g root "$key_path" "$ROOT_MNT/etc/ssh/sops_ed25519_key"

echo "--------------------------------------------------"
echo "Performing NixOS install..."
sudo nixos-install --flake "$flake"
