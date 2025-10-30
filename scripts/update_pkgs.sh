#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
PKGS_DIR="$REPO_DIR/pkgs"

grep -P "(pkgs\.)?callPackage" "$PKGS_DIR/default.nix" \
  | while read line; do
    pkg_name="$(grep -oP "^\s*\K[a-zA-Z0-9_\-]+" <<<"$line")"
    rel_path="$(grep -oP "callPackage\s+\K[a-zA-Z0-9_\-\.\/]+" <<<"$line")"

    abs_path="$(readlink -m "$PKGS_DIR/$rel_path")"
    pkg_dir="$(dirname "$abs_path")"

    # Execute updates in sub-shells
    if [[ "$(basename "$abs_path")" == "package.nix" ]] \
      && [[ -f "$pkg_dir/update.sh" ]]; then
      (cd "$pkg_dir" && ./update.sh)
    else
      (cd "$REPO_DIR" && nix-update "$pkg_name" --flake)
    fi
  done
