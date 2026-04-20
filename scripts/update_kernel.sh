#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils curl jq

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
UPDATE_COOLDOWN=21
SECONDS_PER_DAY=86400

releases="$(curl -sSf https://endoflife.date/api/v1/products/linux/)"

latest_release="$(jq -r '.result.releases[0].releaseDate' <<<"$releases")"
days_since=$((($(date +%s) - $(date -d "$latest_release" +%s)) / SECONDS_PER_DAY))

previous_eol="$(jq -r '.result.releases[1].isEol' <<<"$releases")"

index=1
if ((days_since >= UPDATE_COOLDOWN)) || [[ "$previous_eol" == "true" ]]; then
  index=0
fi

kernel_version="$(jq -r ".result.releases[$index].name" <<<"$releases")"
echo "Pinning kernel version to $kernel_version..."
sed -i "s|linuxVersion = \"[^\"]*\";|linuxVersion = \"$kernel_version\";|" "$REPO_DIR/flake.nix"
