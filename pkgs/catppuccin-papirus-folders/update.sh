#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils nix-update

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$(dirname "$ROOT_DIR")")"
PKG_FILE="$ROOT_DIR/package.nix"
PKG_NAME="$(basename $ROOT_DIR)"

echo "Checking for base package updates..."
(cd "$REPO_DIR" && nix-update "$PKG_NAME" --flake --version=branch)
