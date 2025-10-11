#!/bin/bash

# Script to setup a NixOS system through this repository and given a hostname.

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
if [ "$#" -ne 1 ]; then
  echo "Error: Missing or too many positional arguments."
  echo "Usage: $0 <hostname>"
  exit 1
fi

hostname="$1"
if [ ! -d "$REPO_DIR/hosts/$hostname" ]; then
  echo "Hostname '$hostname' does not exist within this repo at '$REPO_DIR/hosts/$hostname'."
  exit 1
fi

echo "Regenerating hardware config for $hostname..."
nixos-generate-config --show-hardware-config >"$REPO_DIR/hosts/$hostname/hardware-configuration.nix"
sudo nixos-rebuild switch --flake "$REPO_DIR#$hostname"
