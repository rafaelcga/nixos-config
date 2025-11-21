#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p nixos-install-tools coreutils

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") [-n <hostname>]"
  echo "  -n <hostname>  Specify the hostname for which to generate the hardware configuration."
  echo "                 Defaults to the current system's hostname."
  exit 1
}

target_host="$(hostname)"

while getopts ":n:" opt; do
  case ${opt} in
    n) target_host="$OPTARG" ;;
    \?) usage ;;
  esac
done

config_path="$REPO_DIR/hosts/$target_host/hardware-configuration.nix"
mkdir -p "$(dirname "$config_path")"

echo "Generating hardware configuration for '$target_host'..."

if ! config=$(nixos-generate-config --show-hardware-config --no-filesystems 2>&1); then
  echo "[❌] Failed to generate hardware configuration:"
  echo "$config" # This variable now holds stderr
  exit 1
fi

if [[ -z "$config" ]]; then
  echo "[❌] Generated configuration is empty. Aborting."
  exit 1
fi

echo "$config" >"$config_path"
echo "[✔️️] Successfully generated hardware configuration at $config_path"
