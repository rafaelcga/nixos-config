#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p nix-update

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
PKGS_DIR="$REPO_DIR/pkgs"

tput bold
echo "Upgrading local packages..."
tput sgr0
grep -P "(pkgs\.)?callPackage" "$PKGS_DIR/default.nix" \
  | while read line; do
    pkg_name="$(grep -oP "^\s*\K[a-zA-Z0-9_\-]+" <<<"$line")"
    rel_path="$(grep -oP "callPackage\s+\K[a-zA-Z0-9_\-\.\/]+" <<<"$line")"

    abs_path="$(readlink -m "$PKGS_DIR/$rel_path")"
    pkg_dir="$(dirname "$abs_path")"

    tput bold
    printf "* %s " "$pkg_name"
    tput sgr0
    if [[ "$(basename "$abs_path")" == "package.nix" ]] \
      && [[ -f "$pkg_dir/update.sh" ]]; then
      echo "through custom script..."
      (cd "$pkg_dir" && ./update.sh)
    else
      set +e
      (
        cd "$REPO_DIR"
        update_line="$(
          nix-update "$pkg_name" --flake 2>&1 \
            | grep -oP "Update \K\S+ -> \S+(?= in $abs_path)"
        )"
        if [[ -z $update_line ]]; then
          echo "[✔️️] up-to-date"
        else
          echo "[✔️️] updated: $update_line"
        fi
      )
      set -e
    fi
  done
