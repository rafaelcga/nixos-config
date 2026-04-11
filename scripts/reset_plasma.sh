#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils

BACKUP_DIR="$HOME/plasma-config-backup"

mkdir -p "$BACKUP_DIR"

find "$HOME/.config" "$HOME/.local/share" "$HOME/.cache" -maxdepth 1 \
  \( -iname "*plasma*" -o -iname "*kde*" -o -iname "*kwin*" \) \
  | while read path; do
    mv "$path" "$BACKUP_DIR"
  done
