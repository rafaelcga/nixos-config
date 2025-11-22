#!/usr/bin/env nix-shell
#!nix-shell --quiet -i bash -p coreutils nixos-anywhere

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$ROOT_DIR")"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") -n <hostname> -k <ssh_key_path> <user@host>"
  echo ""
  echo "Performs a remote NixOS installation on a machine reachable via SSH using nixos-anywhere."
  echo ""
  echo "Options:"
  echo "  -t                   Do a dry-run, testing the install on a VM."
  echo "  -n <hostname>        (Required) The hostname to install, corresponding to a configuration in the './hosts' directory."
  echo "  -k <ssh_key_path>    (Required) Path to the SSH private key to connect to the remote machine."
  echo "  <user@host>          (Required) The user and address of the remote machine to install to."
  exit 1
}

hostname=""
key_path=""
do_test="false"

while getopts ":n:k:t" opt; do
  case $opt in
    n) hostname="$OPTARG" ;;
    k) key_path="$(realpath "$OPTARG")" ;;
    t) do_test="true" ;;
    \?) usage ;;
  esac
done
# Remove getopts parsed args from parameter list
shift $((OPTIND - 1))

if [[ -z "$hostname" ||
  -z "$key_path" ||
  ("$#" -ne 1 && "$do_test" == "false") ]]; then
  echo "Error: Missing required arguments." >&2
  usage
fi

remote=""
if [[ "$#" -eq 1 ]]; then
  remote="$1"
fi

temp="$(mktemp -d)"
function cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

echo "--------------------------------------------------"
echo "Copying SSH key for SOPS secrets..."

temp_ssh="$temp/tmp/ssh/id_ed25519"
mkdir -p "$(dirname "$temp_ssh")"
cp "$key_path" "$temp_ssh"
chmod 600 "$temp_ssh"

echo "--------------------------------------------------"
echo "Performing NixOS install..."

nixos_anywhere_args=(
  --flake "$REPO_DIR#$hostname"
)

if [[ "$do_test" == "true" ]]; then
  nixos_anywhere_args+=(
    --vm-test
  )
else
  nixos_anywhere_args+=(
    --extra-files "$temp"
    --target-host "$remote"
  )
fi

nixos-anywhere "${nixos_anywhere_args[@]}"
