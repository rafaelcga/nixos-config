#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils gnugrep gnused go

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$(dirname "$ROOT_DIR")")"
PKG_FILE="$ROOT_DIR/package.nix"

echo "Checking for Caddy plugin updates..."

grep -oP '"\Kgithub\.com/[^"@]+@[^"]+' "$PKG_FILE" | while read -r plugin; do
  printf " %s " "$plugin"

  plugin_path="${plugin%@*}"
  old_version="${plugin#*@}"
  # The Go module is github.com/<owner>/<repo>; plugins may be subpackages of it
  module="$(cut -d/ -f1-3 <<<"$plugin_path")"

  if ! new_version="$(go list -m -f '{{.Version}}' "$module@latest" 2>/dev/null)" || [[ -z "$new_version" ]]; then
    echo "[❌] error: could not find the latest version"
    continue
  fi

  if [[ "$old_version" != "$new_version" ]]; then
    sed -i "s|\"$plugin\"|\"$plugin_path@$new_version\"|" "$PKG_FILE"
    echo "[✔️] updated: $old_version -> $new_version"
  else
    echo "[✔️] up-to-date"
  fi
done

echo "Updating derivation hash..."
sed -i -E 's|hash = "[^"]*"|hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="|' "$PKG_FILE"
"$REPO_DIR/scripts/update_hash.sh" -p "$PKG_FILE"
