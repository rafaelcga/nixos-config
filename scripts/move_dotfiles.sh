#!/bin/bash

# Script to move all dotfiles and dot-folders in the current user's directory
# to a timestamped backup directory.

# Create and check backup directory
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$BACKUP_DIR"
if [ ! -d "$BACKUP_DIR" ]; then
  echo "Error: Failed to create backup directory. Aborting."
  exit 1
fi

for item in "$HOME"/.*; do
  [ -e "$item" ] || continue # Skip if file does not exist (no files found)

  base_name=$(basename "$item")
  # Skip '.', '..' and avoid moving backup directory into itself
  if [ "$base_name" = "." ] || [ "$base_name" = ".." ] || ["$item" = "$BACKUP_DIR"]; then
    continue
  fi
  if [ -L "$item" ]; then
    echo " -> Skipping symbolic link: '$base_name'"
    continue
  fi

  echo " -> Moving '$base_name'..."
  mv "$item" "$BACKUP_DIR/"
done

echo "--------------------------------------------------"
echo "✅ Success!"
echo "All dotfiles have been moved to: $BACKUP_DIR"
