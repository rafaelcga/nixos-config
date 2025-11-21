#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils gnused

set -euo pipefail

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
    \?) usage ;;
  esac
done

if [[ -z "$pkg_path" || ! -f "$pkg_path" ]]; then
  echo "Error: A valid path to a .nix package file is required." >&2
  usage
fi

echo "Attempting to build $pkg_path to detect hash..."

# Temporarily disable exit-on-error to capture the output of a failing build
set +e
output=$(nix-build -E "with import <nixpkgs> {}; callPackage $pkg_path {}" 2>&1)
status=$?
set -e

if [[ $status -eq 0 ]]; then
  echo "[✔️] Hash is already up-to-date."
  exit 0
fi

# Use \K to ignore lookbehind match
old_hash=$(echo "$output" | grep -oP 'specified: *\K(sha256-[\w\+\/=]+)')
new_hash=$(echo "$output" | grep -oP 'got: *\K(sha256-[\w\+\/=]+)')

# If both are non-empty, replace
if [[ -n "$old_hash" && -n "$new_hash" ]]; then
  echo "Hash mismatch detected. Updating file..."
  sed -i "s|$old_hash|$new_hash|" "$pkg_path"
  echo "[✔️] Successfully updated hash in $pkg_path"
  echo "  - Old: $old_hash"
  echo "  + New: $new_hash"
else
  # If the build failed for a reason other than a hash mismatch.
  echo "[❌] Package build failed for a reason other than a hash mismatch."
  echo "--- Nix Build Output ---"
  echo "$output"
  echo "------------------------"
  exit 1
fi
