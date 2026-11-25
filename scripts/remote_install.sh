#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils git nixos-anywhere openssh

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") -n <hostname> (-t | [-k <host_key>] <user@host>)"
  echo ""
  echo "Performs a remote NixOS installation on a machine reachable via SSH using nixos-anywhere."
  echo ""
  echo "Options:"
  echo "  -n <hostname>   (Required) The hostname to install, corresponding to a configuration in the './hosts' directory."
  echo "  -t              Do a dry-run, testing the install on a VM."
  echo "  -k <host_key>   Existing SSH host private key to install (e.g. to keep the identity across"
  echo "                  reinstalls). Without it, a new host key is generated and enrolled for sops."
  echo "  <user@host>     The user and address of the remote machine to install to."
  echo ""
  echo "The host key becomes the machine's only sops identity (see scripts/enroll_host.sh); no"
  echo "personal key is copied to the target."
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
  if [[ $# -ne 1 || (-n "$key_path" && ! -f "$key_path") ]]; then
    echo "Error: A real install needs <user@host> (and -k must point to an existing key)." >&2
    usage
  fi

  extra_files="$(mktemp -d)"
  trap 'rm -rf "$extra_files"' EXIT
  ssh_dir="$extra_files/etc/ssh"

  echo "--------------------------------------------------"
  if [[ -n "$key_path" ]]; then
    echo "Using the existing host key $key_path..."
    install -D -m 600 "$key_path" "$ssh_dir/ssh_host_ed25519_key"
    ssh-keygen -y -f "$ssh_dir/ssh_host_ed25519_key" >"$ssh_dir/ssh_host_ed25519_key.pub"
    "$REPO_DIR/scripts/enroll_host.sh" -n "$hostname" -p "$ssh_dir/ssh_host_ed25519_key.pub"
  else
    echo "Generating and enrolling a new host key..."
    "$REPO_DIR/scripts/enroll_host.sh" -n "$hostname" -g "$ssh_dir"
  fi
  chmod 644 "$ssh_dir/ssh_host_ed25519_key.pub"

  args+=(--extra-files "$extra_files" --target-host "$1")
fi

echo "--------------------------------------------------"
echo "Performing NixOS install..."
nixos-anywhere "${args[@]}"

if ! $do_test; then
  echo "--------------------------------------------------"
  echo "[⚠️] Commit and push the enrollment now: the installed system (and its"
  echo "     auto-upgrade) can only decrypt secrets from a revision that has it."
  echo "    git commit -m \"(sops) enroll $hostname\" && git push"
fi
