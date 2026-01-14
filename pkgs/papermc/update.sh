#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils gnused curl jq

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$(dirname "$ROOT_DIR")")"
PKG_FILE="$ROOT_DIR/package.nix"

USER_AGENT="rafaelcga/nixos-config/1.0.0 (https://github.com/rafaelcga)"

minecraft_version="$(curl -s -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/paper \
  | jq -r '.versions | to_entries[0] | .value[0]')"
builds="$(curl -s -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/paper/versions/${minecraft_version}/builds)"

read -r build_id build_url <<<"$(echo "$builds" | jq -r 'first(.[] | select(.channel == "STABLE") | "\(.id) \(.downloads."server:default".url)") // "null null"')"

if [[ "$build_id" == "null" || "$build_url" == "null" ]]; then
  echo "[❌] error: Could not fetch latest build."
  exit 1
fi

new_version="$minecraft_version-$build_id"
old_version="$(grep -oP "version\s?\=\s?\"\K[0-9\-\.]*" "$PKG_FILE")"

if [[ "$old_version" != "$new_version" ]]; then
  hash_value="$(curl -sSfL "$build_url" | openssl dgst -sha256 -binary | base64 -w0)"
  sed -i \
    -e "s|\(version\s*=\s*\"\)[^\"]*\"|\1$new_version\"|" \
    -e "s|\(hash\s*=\s*\"\)[^\"]*\"|\1sha256-$hash_value\"|" \
    -e "s|\(url\s*=\s*\"\)[^\"]*\"|\1$build_url\"|" \
    "$PKG_FILE"
  echo "[✔️] updated: $old_version -> $new_version"
else
  echo "[✔️] up-to-date"
fi
