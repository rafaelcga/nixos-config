#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p git disko

set -euo pipefail

ROOT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
REPO_URL="https://github.com/rafaelcga/nixos-config.git"
TEMP_SSH="/mnt/tmp/ssh/id_ed25519"

repo_name="$(
  grep -oP "(https://)?github.com/[a-zA-Z0-9_\-]+/\K[a-zA-Z0-9_\-]+(?=.git)" \
    <<<"$REPO_URL"
)"
repo_dir="$(pwd)/$repo_name"

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

echo "Cloning configuration repo..."
git clone "$REPO_URL"

echo "--------------------------------------------------"
(cd $ROOT_DIR && ./generate_hwcfg.sh -n "$hostname")
(cd $repo_dir && git add "$repo_dir/hosts/$hostname/hardware-configuration.nix")

echo "--------------------------------------------------"
echo "Formatting disks..."
disko --mode destroy,format,mount "$repo_dir/hosts/$hostname"

echo "--------------------------------------------------"
echo "Copying SSH key for SOPS secrets..."
mkdir -p "$(dirname "$TEMP_SSH")"
cp "$key_path" "$TEMP_SSH"
sudo chown root:root "$TEMP_SSH"
sudo chmod 600 "$TEMP_SSH"

echo "--------------------------------------------------"
echo "Performing NixOS install..."
(cd $repo_dir && sudo nixos-install --flake ".#$hostname")
