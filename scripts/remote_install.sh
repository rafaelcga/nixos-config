#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils nixos-anywhere

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") -n <hostname> (-t | -k <ssh_key_path> <user@host>)"
  echo ""
  echo "Performs a remote NixOS installation on a machine reachable via SSH using nixos-anywhere."
  echo ""
  echo "Options:"
  echo "  -n <hostname>        (Required) The hostname to install, corresponding to a configuration in the './hosts' directory."
  echo "  -t                   Do a dry-run, testing the install on a VM."
  echo "  -k <ssh_key_path>    Path to the SSH private key for SOPS to access secrets on the installed system."
  echo "  <user@host>          The user and address of the remote machine to install to."
  exit 1
}

hostname=""
key_path=""
do_test=false
while getopts ":n:k:t" opt; do
  case $opt in
    n) hostname="$OPTARG" ;;
    k) key_path="$OPTARG" ;;
    t) do_test=true ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

args=(--flake "$REPO_DIR#$hostname")

if [[ -z "$hostname" ]]; then
  echo "Error: Missing hostname." >&2
  usage
elif $do_test; then
  args+=(--vm-test)
else
  if [[ ! -f "$key_path" || $# -ne 1 ]]; then
    echo "Error: A real install needs -k <ssh_key_path> and <user@host>." >&2
    usage
  fi

  echo "--------------------------------------------------"
  echo "Copying SSH key for SOPS secrets..."
  extra_files="$(mktemp -d)"
  trap 'rm -rf "$extra_files"' EXIT
  install -D -m 600 "$key_path" "$extra_files/etc/ssh/sops_ed25519_key"

  args+=(--extra-files "$extra_files" --target-host "$1")
fi

echo "--------------------------------------------------"
echo "Performing NixOS install..."
nixos-anywhere "${args[@]}"
