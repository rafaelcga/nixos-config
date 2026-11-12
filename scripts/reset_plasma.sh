#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils findutils

set -euo pipefail

# Timestamped so re-runs never collide; keeps each file's original location.
BACKUP_DIR="$HOME/plasma-config-backup/$(date +%Y%m%d-%H%M%S)"

for dir in .config .local/share .cache; do
  [[ -d "$HOME/$dir" ]] || continue
  mkdir -p "$BACKUP_DIR/$dir"
  find "$HOME/$dir" -mindepth 1 -maxdepth 1 \
    \( -iname "*plasma*" -o -iname "*kde*" -o -iname "*kwin*" \) \
    -exec mv -t "$BACKUP_DIR/$dir" {} +
done

echo "Plasma configuration moved to $BACKUP_DIR"
