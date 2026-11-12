#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils gnugrep "nix-update.override { nix = lix; }"

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
cd "$REPO_DIR"

# Packages with an update.sh use it; the rest go through nix-update directly.
function update_pkg() {
  local pkg="$1"

  if [[ -f "pkgs/$pkg/update.sh" ]]; then
    echo "through custom script..."
    (cd "pkgs/$pkg" && ./update.sh)
    return
  fi

  # Overrides that reuse nixpkgs' `src` have nothing of their own to update
  if ! grep -q 'src = ' "pkgs/$pkg/package.nix"; then
    echo "[↷] skipped: source tracked by nixpkgs"
    return
  fi

  local output change
  if ! output="$(nix-update "$pkg" --flake 2>&1)"; then
    echo "  ${output//$'\n'/$'\n'  }"
    return 1
  fi

  change="$(grep -oP 'Update \K\S+ -> \S+' <<<"$output" || true)"
  if [[ -n "$change" ]]; then
    echo "[✔️] updated: $change"
  else
    echo "[✔️] up-to-date"
  fi
}

echo "Upgrading local packages..."

failed=0
for pkg_file in pkgs/*/package.nix; do
  pkg="$(basename "$(dirname "$pkg_file")")"
  printf "❖ %s " "$pkg"
  if ! update_pkg "$pkg"; then
    echo "  [❌] $pkg update failed"
    failed=1
  fi
done

if ((failed)); then
  echo "❌ One or more package updates failed."
  exit 1
fi
