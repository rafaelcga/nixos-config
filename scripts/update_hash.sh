#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils gnugrep gnused

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") -p <path_to_nix_file>"
  echo ""
  echo "Automatically updates the hash for a fixed-output derivation."
  echo ""
  echo "  -p <path>    (Required) Path to the .nix file containing the package derivation."
  exit 1
}

pkg_path=""
while getopts ":p:" opt; do
  case $opt in
    p) pkg_path="$(realpath "$OPTARG")" ;;
    *) usage ;;
  esac
done

if [[ ! -f "$pkg_path" ]]; then
  echo "Error: A valid path to a .nix package file is required." >&2
  usage
fi

if [[ "$(basename "$pkg_path")" == "package.nix" ]]; then
  pkg_name="$(basename "$(dirname "$pkg_path")")"
else
  pkg_name="$(basename "$pkg_path" .nix)"
fi

echo "Attempting to build $pkg_name to detect hash..."
if output="$(nix build "$REPO_DIR#$pkg_name" --no-link --print-build-logs 2>&1)"; then
  echo "[✔️] Hash is already up-to-date."
  exit 0
fi

old_hash="$(grep -oP 'specified: *\Ksha256-[\w+/=]+' <<<"$output" || true)"
new_hash="$(grep -oP 'got: *\Ksha256-[\w+/=]+' <<<"$output" || true)"

if [[ -z "$old_hash" || -z "$new_hash" ]]; then
  echo "[❌] Package build failed for a reason other than a hash mismatch."
  echo "--- Nix Build Output ---"
  echo "$output"
  echo "------------------------"
  exit 1
fi

echo "Hash mismatch detected. Updating file..."
sed -i "s|$old_hash|$new_hash|" "$pkg_path"
echo "[✔️] Successfully updated hash in $pkg_path"
echo "  - Old: $old_hash"
echo "  + New: $new_hash"
