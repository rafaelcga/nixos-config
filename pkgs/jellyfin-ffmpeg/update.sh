#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils curl jq nix-prefetch-github

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$(dirname "$ROOT_DIR")")"
PKG_FILE="$ROOT_DIR/package.nix"

echo "Fetching latest version from GitHub..."
new_version=$(
  curl -s https://api.github.com/repos/jellyfin/jellyfin-ffmpeg/releases/latest \
    | jq -r .tag_name \
    | sed 's/^v//'
)
old_version=$(grep -oP 'version\s*=\s*"\K[^"]+' "$PKG_FILE")

if [[ -z "$new_version" || "$new_version" == "null" ]]; then
  echo "[❌] error: Could not find latest version."
  exit 1
fi

if [[ "$old_version" != "$new_version" ]]; then
  sed -i -E "s|version\s+=\s+\"[^\"]*\";|version = \"$new_version\";|" "$PKG_FILE"
  echo "Updating hashes..."
  new_hash=$(
    nix-prefetch-github jellyfin jellyfin-ffmpeg --rev v${new_version} \
      | jq -r .hash
  )
  sed -i -E "0,\|hash\s+=\s+\"[^\"]*\"|s||hash = \"$new_hash\"|" "$PKG_FILE"
  echo "[✔️] updated: $old_version -> $new_version"
else
  echo "[✔️] up-to-date"
fi
