#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils "nix-update.override { nix = lix; }"

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$(dirname "$ROOT_DIR")")"
PKG_NAME="$(basename "$ROOT_DIR")"

echo "Checking for base package updates..."
(cd "$REPO_DIR" && nix-update "$PKG_NAME" --flake --version=branch)
