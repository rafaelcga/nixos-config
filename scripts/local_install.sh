#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p nixos-install-tools coreutils git disko

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$ROOT_DIR")"

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
    k) key_path="$(realpath "$OPTARG")" ;;
    \?) usage ;;
  esac
done

if [[ -z "$hostname" || -z "$key_path" ]]; then
  echo "Error: Missing required arguments." >&2
  usage
fi

temp="$(mktemp -d)"
function cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Generate hardware-configuration.nix
echo "--------------------------------------------------"
(cd $ROOT_DIR && ./generate_hardware.sh -n "$hostname")

echo "--------------------------------------------------"
echo "Formatting disks..."

# Import all modules from NixOS configuration in flake-parts
temp_config="$(mktemp $temp/disko-config.XXXXXX.nix)"
cat >"$temp_config" <<EOF
{
    imports = [
        "$REPO_DIR/overlays"
        "$REPO_DIR/modules/nixos"
        "$REPO_DIR/hosts/core.nix"
        "$REPO_DIR/hosts/$hostname"
    ];
}
EOF
disko --mode destroy,format,mount "$temp_config"

echo "--------------------------------------------------"
echo "Copying SSH key for SOPS secrets..."

temp_ssh="/mnt/tmp/ssh/id_ed25519"
mkdir -p "$(dirname "$temp_ssh")"
cp "$key_path" "$temp_ssh"
sudo chown root:root "$temp_ssh"
sudo chmod 600 "$temp_ssh"

echo "--------------------------------------------------"
echo "Performing NixOS install..."
(cd $repo_dir && sudo nixos-install --flake ".#$hostname")
