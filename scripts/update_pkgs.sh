#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p nix-update

set -euo pipefail

# ANSI formatting codes for TTY
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
else
  BOLD=""
  RESET=""
fi

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
PKGS_DIR="$REPO_DIR/pkgs"

echo "${BOLD}Upgrading local packages...${RESET}"

find "$PKGS_DIR" -name "*.nix" -not -name "default.nix" \
  | while read abs_path; do
    if [[ "$(basename "$abs_path")" == "package.nix" ]]; then
      pkg_name=$(basename "$(dirname "$abs_path")")
    else
      pkg_name=$(basename "$abs_path" .nix)
    fi

    printf "%s❖ %s%s " "$BOLD" "$pkg_name" "$RESET"

    pkg_dir="$(dirname "$abs_path")"
    set +e
    if [[ "$(basename "$abs_path")" == "package.nix" ]] \
      && [[ -f "$pkg_dir/update.sh" ]]; then
      echo "through custom script..."
      (cd "$pkg_dir" && ./update.sh)
    else
      (
        cd "$REPO_DIR" # nix-update needs to be launched on the flake's directory

        output="$(nix-update "$pkg_name" --flake 2>&1)"
        status=$?

        update_line="$(grep -oP "Update \K\S+ -> \S+(?= in $abs_path)" <<<"$output")"

        if [[ $status -eq 0 ]] && [[ -z $update_line ]]; then
          echo "[✔️️] up-to-date"
        elif [[ $status -eq 0 ]]; then
          echo "[✔️️] updated: $update_line"
        else
          echo "[❌] update failed:"
          echo "$output"
        fi
      )
    fi
    set -e
  done
