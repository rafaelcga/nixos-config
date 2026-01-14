#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils gnused curl jq

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$(dirname "$ROOT_DIR")")"
PKG_FILE="$ROOT_DIR/package.nix"

echo "Checking for Caddy plugin updates..."

grep -oP "github.com/\K([a-zA-Z0-9_\-]+/?)+@[^\"]+" "$PKG_FILE" \
  | while read -r plugin; do
    splits=($(sed "s|[/@]|\n|g" <<<"$plugin"))
    printf " %s " "$plugin"

    repo_owner="${splits[0]}"
    repo_name="${splits[1]}"
    old_version="${splits[-1]}"

    new_version=$(
      curl -sfL -A "nixos-config-update-script/1.0" \
        "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest" \
        | jq -r ".tag_name"
    )

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
