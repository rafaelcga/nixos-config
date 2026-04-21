#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils gnused curl jq

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
UPDATE_COOLDOWN=21
SECONDS_PER_DAY=86400

echo "Fetching latest Linux kernel releases from endoflife.date..."
if ! releases="$(curl -sSf https://endoflife.date/api/v1/products/linux/)"; then
  echo "Failed to fetch data from the API."
fi

latest_release="$(jq -r '.result.releases[0].releaseDate' <<<"$releases")"
days_since=$((($(date +%s) - $(date -d "$latest_release" +%s)) / SECONDS_PER_DAY))
previous_eol="$(jq -r '.result.releases[1].isEol' <<<"$releases")"

echo "   ├─ Latest release date: $latest_release ($days_since days ago)"
echo "   └─ Previous release EOL: $previous_eol"

index=1
reason="Cooldown ($UPDATE_COOLDOWN days) not met & previous is still supported."

if ((days_since >= UPDATE_COOLDOWN)); then
  index=0
  reason="Update cooldown ($UPDATE_COOLDOWN days) has been met."
elif [[ "$previous_eol" == "true" ]]; then
  index=0
  reason="Previous kernel release is End-of-Life (EOL)."
fi

kernel_version="$(jq -r ".result.releases[$index].name" <<<"$releases")"

echo "Target kernel: $kernel_version. $reason"
echo "   └─ Updating flake.nix..."

sed -i "s|linuxVersion = \"[^\"]*\";|linuxVersion = \"$kernel_version\";|" "$REPO_DIR/flake.nix"

echo "Kernel version pinned successfully!"
