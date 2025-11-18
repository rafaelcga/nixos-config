#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p git disko

set -euo pipefail

ROOT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$ROOT_DIR")"
TEMP_SSH="/mnt/tmp/ssh/id_ed25519"

hostname=""
key_path=""

while getopts ":n:k:" opt; do
  case ${opt} in
    n) hostname="$OPTARG" ;;
    k) key_path="$(readlink -f "$OPTARG")" ;;
    \?) echo "Usage: $(basename "${BASH_SOURCE[0]}") [-n] [-k]" ;;
  esac
done

if [ -z "$hostname" ] || [ -z "$key_path" ]; then
  echo "Hostname and input SSH key path must be defined."
  exit 1
fi

echo "--------------------------------------------------"
(cd $ROOT_DIR && ./generate_hardware.sh -n "$hostname")
(cd $REPO_DIR && git add "$REPO_DIR/hosts/$hostname/hardware-configuration.nix")

echo "--------------------------------------------------"
echo "Formatting disks..."
tmp_config=$(mktemp /tmp/disko-config.XXXXXX.nix)
# Import all modules from NixOS configuration in flake-parts
cat >"$tmp_config" <<EOF
{
    imports = [
        "$REPO_DIR/overlays"
        "$REPO_DIR/modules/nixos"
        "$REPO_DIR/hosts/core.nix"
        "$REPO_DIR/hosts/$hostname"
    ];
}
EOF
disko --mode destroy,format,mount "$tmp_config"

echo "--------------------------------------------------"
echo "Copying SSH key for SOPS secrets..."
mkdir -p "$(dirname "$TEMP_SSH")"
cp "$key_path" "$TEMP_SSH"
sudo chown root:root "$TEMP_SSH"
sudo chmod 600 "$TEMP_SSH"

echo "--------------------------------------------------"
echo "Performing NixOS install..."
(cd $repo_dir && sudo nixos-install --flake ".#$hostname")
