#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p nix-update

set -euox pipefail

# Set TERM for tput, if not already set
export TERM="${TERM:-xterm}"

REPO_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
PKGS_DIR="$REPO_DIR/pkgs"

tput bold
echo "Upgrading local packages..."
tput sgr0
grep -P "(pkgs\.)?callPackage" "$PKGS_DIR/default.nix" \
  | while read line; do
    pkg_name="$(grep -oP "^\s*\K[a-zA-Z0-9_\-]+" <<<"$line")"
    rel_path="$(grep -oP "callPackage\s+\K[a-zA-Z0-9_\-\.\/]+" <<<"$line")"

    tput bold
    printf "❖ %s " "$pkg_name"
    tput sgr0

    abs_path="$(readlink -m "$PKGS_DIR/$rel_path")"
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
          echo "[❌] update failed"
        fi
      )
    fi
    set -e
  done
