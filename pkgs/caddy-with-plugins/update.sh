#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p curl jq

set -euo pipefail

ROOT_DIR="$(dirname "$(readlink -f "$0")")"

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

set +e
output=$(nix-build -E \
  "with import <nixpkgs> {}; callPackage $ROOT_DIR/package.nix {}" 2>&1)

if [[ $? -ne 0 ]]; then
  set -e
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
  sed -i "s|$old_hash|$new_hash|" "$ROOT_DIR/package.nix"
  echo " [✔️] Updated hash:"
  echo "  - $old_hash"
  echo "  + $new_hash"
else
  echo " [✔️] Hash already up-to-date"
fi
