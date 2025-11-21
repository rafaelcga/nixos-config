#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils gnused nix-update

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
PKGS_DIR="$REPO_DIR/pkgs"

function has_custom_update() {
  local abs_path="$1"
  [[ "$(basename "$abs_path")" == "package.nix" && -f "$(dirname "$abs_path")/update.sh" ]]
}

function run_custom_update() {
  local abs_path="$1"
  echo "through custom script..."
  (cd "$(dirname "$abs_path")" && ./update.sh)
}

function run_nix_update() {
  local pkg_name="$1"

  (
    cd "$REPO_DIR" # nix-update needs to be launched on the flake's directory

    set +e
    local output # separate declaration and assignment for correct status capture
    output="$(nix-update "$pkg_name" --flake 2>&1)"
    local status=$?
    set -e

    local update_line="$(grep -oP "Update \K\S+ -> \S+" <<<"$output")"

    if [[ $status -eq 0 ]]; then
      if [[ -n "$update_line" ]]; then
        echo "[✔️️] updated: $update_line"
      else
        echo "[✔️️] up-to-date"
      fi
    else
      echo "[❌] update failed:"
      # Indent the output for readability
      echo "$output" | sed 's/^/  /'
    fi
  )
}

echo "Upgrading local packages..."

find "$PKGS_DIR" -name "*.nix" -not -name "default.nix" \
  | while read abs_path; do
    if [[ "$(basename "$abs_path")" == "package.nix" ]]; then
      pkg_name=$(basename "$(dirname "$abs_path")")
    else
      pkg_name=$(basename "$abs_path" .nix)
    fi

    printf "❖ %s " "$pkg_name"

    if has_custom_update "$abs_path"; then
      run_custom_update "$abs_path"
    else
      run_nix_update "$pkg_name"
    fi
  done
