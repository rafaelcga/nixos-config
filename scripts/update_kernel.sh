#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils gnugrep gnused curl jq

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
FLAKE="$REPO_DIR/flake.nix"
UPDATE_COOLDOWN=14

echo "Fetching latest Linux kernel releases from endoflife.date..."
releases="$(curl -sSf https://endoflife.date/api/v1/products/linux/)"

IFS=$'\t' read -r latest latest_date previous previous_eol < <(
  jq -r '.result.releases | [.[0].name, .[0].releaseDate, .[1].name, .[1].isEol] | @tsv' <<<"$releases"
)
days_since=$((($(date +%s) - $(date -d "$latest_date" +%s)) / 86400))

echo "   ├─ Latest release: $latest ($latest_date, $days_since days ago)"
echo "   └─ Previous release: $previous (EOL: $previous_eol)"

if ((days_since >= UPDATE_COOLDOWN)); then
  candidates=("$latest" "$previous")
  reason="Update cooldown ($UPDATE_COOLDOWN days) has been met."
elif [[ "$previous_eol" == "true" ]]; then
  candidates=("$latest" "$previous")
  reason="Previous kernel release is End-of-Life (EOL)."
else
  candidates=("$previous" "$latest")
  reason="Cooldown ($UPDATE_COOLDOWN days) not met & previous is still supported."
fi
echo "Preferred kernel: ${candidates[0]}. $reason"

current="$(grep -oP 'linuxVersion = "\K[^"]*' "$FLAKE")" || {
  echo "[❌] No linuxVersion line found in $FLAKE" >&2
  exit 1
}

# Pin the first candidate that the flake's locked nixpkgs actually packages.
for version in "${candidates[@]}"; do
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "[❌] Unexpected kernel version from API: '$version'" >&2
    exit 1
  fi
  attr="linuxPackages_${version/./_}"
  if pkg_version="$(nix eval --raw --inputs-from "$REPO_DIR" \
    "nixpkgs#legacyPackages.x86_64-linux.$attr.kernel.version" 2>/dev/null)"; then
    echo "   └─ nixpkgs provides $attr ($pkg_version)"
    sed -i "s|linuxVersion = \"[^\"]*\";|linuxVersion = \"$version\";|" "$FLAKE"
    echo "[✔️] Kernel pinned to $version (was $current)"
    exit 0
  fi
  echo "   └─ nixpkgs does not provide $attr, skipping"
done

echo "[⚠️] No candidate kernel is in nixpkgs; keeping $current"
