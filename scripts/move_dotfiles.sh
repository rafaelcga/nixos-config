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
