#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

set -euo pipefail

ROOT_DIR=$(dirname "$0")

update_plugins() {
  echo "Checking for Caddy plugin updates..."

  for plugin in $(grep -oP "github.com/([a-zA-Z0-9_-]+/?)+@[^\"]+" "$ROOT_DIR/package.nix"); do
    local parts=($(sed "s|[/@]|\n|g" <<<"$plugin"))
    local plugin_name=$(grep -oP "(?<=github.com/)([a-zA-Z0-9_-]+/?)+(?=@.+)" <<<"$plugin")
    printf "* %s... " "$plugin_name"

    local old_version="${parts[-1]}"
    local new_version=$(
      curl -sL "https://api.github.com/repos/${parts[1]}/${parts[2]}/releases/latest" \
        | jq -r ".tag_name"
    )

    if [[ -z "$new_version" ]]; then
      echo "[!] ERROR: Could not find latest version."
      continue
    fi

    if [[ "$old_version" != "$new_version" ]]; then
      local updated_plugin=$(sed -E "s|$old_version|$new_version|" <<<"$plugin")
      sed -i "s|$plugin|$updated_plugin|" "$ROOT_DIR/package.nix"
      echo "[✔] UPDATE APPLIED: $old_version -> $new_version"
    else
      echo "[✔] UP-TO-DATE"
    fi
  done
}

update_hash() {
  echo "Updating derivation hash..."

  # Replace non-valid strings by a fake hash
  fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  if ! grep -qP "hash\s*=\s*\"sha256-[A-Za-z0-9\+\/]+=\"" "$ROOT_DIR/package.nix"; then
    echo "[!] WARNING: Non-valid string found in hash, replacing with fake hash \"$fake_hash\"."
    sed -i "s|\(hash\s*=\s*\"\).*\(\";\)|\1$fake_hash\2|" "$ROOT_DIR/package.nix"
  fi

  set +e
  local output
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
    echo "[✔] UPDATED HASH:"
    echo "  - $old_hash"
    echo "  + $new_hash"
  else
    echo "[✔] HASH ALREADY UP-TO-DATE"
  fi
}

update_plugins

echo ""
echo "--------------------------------------------------"
echo ""

update_hash
