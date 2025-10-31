#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"

hostname="$(hostname)"

while getopts ":n:" opt; do
  case ${opt} in
    n) hostname="$OPTARG" ;;
    \?) echo "Usage: $(basename "${BASH_SOURCE[0]}") [-n]" ;;
  esac
done

config_path="$REPO_DIR/hosts/$hostname/hardware-configuration.nix"

echo "Generating hardware configuration..."
config="$(nixos-generate-config --show-hardware-config --no-filesystems 2>/dev/null)"
echo "$config" >"$config_path"
echo "[✔️️] Successfully generated hardware configuration at $config_path"
