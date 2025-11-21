#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p curl jq

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$(dirname "$ROOT_DIR")")"

echo "Checking for Caddy plugin updates..."

grep -oP "github.com/([a-zA-Z0-9_\-]+/?)+@[^\"]+" "$ROOT_DIR/package.nix" \
  | while read plugin; do
    parts=($(sed "s|[/@]|\n|g" <<<"$plugin"))
    plugin_name=$(grep -oP "(?<=github.com/)([a-zA-Z0-9_\-]+/?)+(?=@.+)" <<<"$plugin")
    printf " %s " "$plugin_name"

    old_version="${parts[-1]}"
    new_version=$(
      curl -sL "https://api.github.com/repos/${parts[1]}/${parts[2]}/releases/latest" \
        | jq -r ".tag_name"
    )

    if [[ -z "$new_version" ]]; then
      echo "[❌] error: Could not find latest version."
      continue
    fi

    if [[ "$old_version" != "$new_version" ]]; then
      updated_plugin=$(sed -E "s|$old_version|$new_version|" <<<"$plugin")
      sed -i "s|$plugin|$updated_plugin|" "$ROOT_DIR/package.nix"
      echo "[✔️] updated: $old_version -> $new_version"
    else
      echo "[✔️] up-to-date"
    fi
  done

echo "Updating derivation hash..."

# Replace non-valid strings by a fake hash
fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
if ! grep -qP "hash\s*=\s*\"sha256-[A-Za-z0-9\+\/]+=\"" "$ROOT_DIR/package.nix"; then
  echo " [❗] Warning: Non-valid string found in hash, replacing with fake hash \"$fake_hash\"."
  sed -i "s|\(hash\s*=\s*\"\).*\(\";\)|\1$fake_hash\2|" "$ROOT_DIR/package.nix"
fi

(cd "$REPO_DIR/scripts" && ./update_hash.sh -p "$ROOT_DIR/package.nix")
