#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils gnugrep gnused curl jq go

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$(dirname "$ROOT_DIR")")"
PKG_FILE="$ROOT_DIR/package.nix"

echo "Checking for Caddy plugin updates..."

grep -oP "github.com/([a-zA-Z0-9_\-]+/?)+@[^\"]+" "$PKG_FILE" \
  | while read -r plugin; do
    printf " %s " "$plugin"

    plugin_path="${plugin%@*}"
    old_version="${plugin#*@}"
    # Keep only <author>/<repo_name>
    plugin_repo="$(echo "$plugin_path" | cut -d'/' -f1-3)"

    # Grep the plugin version
    {
      rm -f go.mod go.sum
      go mod init temp && go get $plugin_path
    } >/dev/null 2>&1

    new_version="$(grep "$plugin_repo" go.mod | awk '{print $2}')"

    if [[ -z "$new_version" || "$new_version" == "null" ]]; then
      echo "[❌] error: Could not find latest version."
      continue
    fi

    if [[ "$old_version" != "$new_version" ]]; then
      updated_plugin=$(sed -E "s|$old_version|$new_version|" <<<"$plugin")
      sed -i "s|$plugin|$updated_plugin|" "$PKG_FILE"
      echo "[✔️] updated: $old_version -> $new_version"
    else
      echo "[✔️] up-to-date"
    fi
  done

echo "Updating derivation hash..."

# Replace non-valid strings by a fake hash
fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
if ! hash="$(grep -qP "hash\s*=\s*\"\K(sha256-[\w\+\/=]+)" "$PKG_FILE")"; then
  echo "[❗] Warning: Non-valid string found in hash, replacing with fake hash \"$fake_hash\"."
  sed -i "s|$hash|$fake_hash|" "$PKG_FILE"
fi

(cd "$REPO_DIR/scripts" && ./update_hash.sh -p "$PKG_FILE")
