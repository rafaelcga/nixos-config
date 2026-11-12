#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p nixos-install-tools coreutils git

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") [-n <hostname>]"
  echo "  -n <hostname>  Specify the hostname for which to generate the hardware configuration."
  echo "                 Defaults to the current system's hostname."
  exit 1
}

hostname="$(uname -n)"
while getopts ":n:" opt; do
  case $opt in
    n) hostname="$OPTARG" ;;
    *) usage ;;
  esac
done

config_path="$REPO_DIR/hosts/$hostname/hardware-configuration.nix"
echo "Generating hardware configuration for '$hostname'..."

# stderr goes to the terminal, so warnings never end up in the generated file.
config="$(nixos-generate-config --show-hardware-config --no-filesystems)"
if [[ -z "$config" ]]; then
  echo "[❌] Generated configuration is empty. Aborting." >&2
  exit 1
fi

mkdir -p "$(dirname "$config_path")"
echo "$config" >"$config_path"
git -C "$REPO_DIR" add "$config_path"
echo "[✔️] Successfully generated hardware configuration at $config_path"
