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

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
PKGS_DIR="$REPO_DIR/pkgs"

echo "${BOLD}Upgrading local packages...${RESET}"

grep -P "(pkgs\.)?callPackage" "$PKGS_DIR/default.nix" \
  | while read line; do
    pkg_name="$(grep -oP "^\s*\K[a-zA-Z0-9_\-]+" <<<"$line")"
    rel_path="$(grep -oP "callPackage\s+\K[a-zA-Z0-9_\-\.\/]+" <<<"$line")"

    printf "%s❖ %s%s " "$BOLD" "$pkg_name" "$RESET"

    abs_path="$(readlink -m "$PKGS_DIR/$rel_path")"
    if [[ -d $abs_path ]]; then
      pkg_dir="$abs_path"
    else
      pkg_dir="$(dirname "$abs_path")"
    fi

    set +e
    if ([[ "$(basename "$abs_path")" == "package.nix" ]] \
      || [[ -f "$abs_path/default.nix" ]]) \
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
          echo "[❌] update failed"
        fi
      )
    fi
    set -e
  done
