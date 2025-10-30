#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

set -euo pipefail

ROOT_DIR=$(dirname "$0")

update_version() {
  local updated_plugin=$(sed -E "s|@v[\.0-9]+|@$2|" <<<"$1")
  sed -i "s|$1|$updated_plugin|" "$ROOT_DIR/package.nix"
}

update_plugins() {
  for plugin in $(grep -oP "github.com/([a-zA-Z0-9_-]+/?)+@v[\.\d]+" "$ROOT_DIR/package.nix"); do
    local parts=($(sed "s|[/@]|\n|g" <<<"$plugin"))

    local old_version="${parts[-1]}"
    local new_version=$(
      curl -sL "https://api.github.com/repos/${parts[1]}/${parts[2]}/releases/latest" \
        | jq -r ".tag_name"
    )

    if [[ "$old_version" != "$new_version" ]]; then
      update_version "$plugin" "$new_version"
    fi
  done
}

update_hash() {
  # Replace non-valid strings by a fake hash
  fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  if ! grep -qP "hash\s*=\s*\"sha256-[A-Za-z0-9\+\/]+=\"" "$ROOT_DIR/package.nix"; then
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
  fi
}

update_plugins
update_hash
