#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p

set -euo pipefail

pkg_path=""

while getopts ":p:" opt; do
  case ${opt} in
    p) pkg_path="$(readlink -f "$OPTARG")" ;;
    \?) echo "Usage: $(basename "${BASH_SOURCE[0]}") [-p]" ;;
  esac
done

if [[ -z "$pkg_path" ]] || [[ ! -f "$pkg_path" ]]; then
  echo "Path to .nix file containing a package required."
  exit 1
fi

set +e
output=$(nix-build -E \
  "with import <nixpkgs> {}; callPackage $pkg_path {}" 2>&1)
status=$?

old_hash=$(
  echo "$output" \
    | grep -oP "specified:\s*sha256-[A-Za-z0-9\+\/]+=" \
    | sed -E "s|^specified:\s*||"
)
new_hash=$(
  echo "$output" \
    | grep -oP "got:\s*sha256-[A-Za-z0-9\+\/]+=" \
    | sed -E "s|^got:\s*||"
)
set -e

if [[ $status -ne 0 ]] && [[ ! -z $old_hash ]]; then
  sed -i "s|$old_hash|$new_hash|" "$pkg_path"
  echo " [✔️] Updated hash:"
  echo "  - $old_hash"
  echo "  + $new_hash"
elif [[ $status -ne 0 ]]; then
  echo " [❌] error: Package build failed."
else
  echo " [✔️] Hash already up-to-date."
fi
