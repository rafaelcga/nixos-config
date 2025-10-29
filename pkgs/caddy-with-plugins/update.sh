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
  echo
}

update_plugins
