#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils diffutils git sops yq-go

# One-time migration of secrets/secrets.yaml (one file, one admin key) into
#   secrets/common.yaml   passwords/user, web_domain, home-VPN public keys
#   secrets/<host>.yaml   that host's home-VPN private key
#   secrets/<server>.yaml additionally every service secret
# Run it after enrolling every host (scripts/enroll_host.sh). Decrypted data
# only lives in a private tmpfs directory, removed on exit.

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") [-s <server hostname>]"
  echo ""
  echo "Splits secrets/secrets.yaml into secrets/common.yaml and secrets/<host>.yaml."
  echo ""
  echo "Options:"
  echo "  -s <hostname>   Host that receives the service secrets (default: beelink)."
  exit 1
}

server="beelink"
while getopts ":s:" opt; do
  case $opt in
    s) server="$OPTARG" ;;
    *) usage ;;
  esac
done

cd "$REPO_DIR"
if [[ ! -f secrets/secrets.yaml ]]; then
  echo "[❌] secrets/secrets.yaml not found: nothing to migrate" >&2
  exit 1
fi
if [[ -f secrets/common.yaml ]]; then
  echo "[❌] secrets/common.yaml already exists: the split was already done" >&2
  exit 1
fi

hosts=()
for host_dir in hosts/*/; do
  host="$(basename "$host_dir")"
  if [[ ! -f "$host_dir/ssh_host_ed25519_key.pub" ]]; then
    echo "[❌] Host '$host' is not enrolled yet: run scripts/enroll_host.sh -n $host ..." >&2
    exit 1
  fi
  hosts+=("$host")
done
if [[ ! " ${hosts[*]} " == *" $server "* ]]; then
  echo "[❌] Server host '$server' not found in ./hosts" >&2
  exit 1
fi

"$REPO_DIR/scripts/update_sops.sh" -c

umask 077
tmp="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/split-secrets.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

sops decrypt secrets/secrets.yaml >"$tmp/all.yaml"

# Home-VPN keys of hosts that no longer exist in ./hosts are dropped
hosts_re="^($(
  IFS='|'
  echo "${hosts[*]}"
))\$"
removed="$(hosts_re="$hosts_re" yq '.wireguard.home_vpn | keys | .[] | select(test(env(hosts_re)) | not)' "$tmp/all.yaml")"
if [[ -n "$removed" ]]; then
  echo "[⚠️] Dropping the home-VPN keys of removed host(s): $(echo "$removed" | paste -sd' ')"
  hosts_re="$hosts_re" yq -i '.wireguard.home_vpn |= with_entries(select(.key | test(env(hosts_re))))' "$tmp/all.yaml"
fi

# Every leaf path, to check that nothing is lost or duplicated
leaves() { yq '.. | select(tag != "!!map") | path | join("/")' "$1" | sort; }

yq '{
  "passwords": {"user": .passwords.user},
  "web_domain": .web_domain,
  "wireguard": {"home_vpn": (.wireguard.home_vpn | map_values({"public_key": .public_key}))}
}' "$tmp/all.yaml" >"$tmp/common.yaml"

for host in "${hosts[@]}"; do
  if [[ "$host" == "$server" ]]; then
    # Everything that is neither shared nor another host's: the service secrets.
    # `github_token` is dropped: no module uses it (revoke it on GitHub).
    host="$host" yq '
      del(.passwords.user) | del(.web_domain) | del(.github_token)
      | .wireguard.home_vpn = {env(host): {"private_key": .wireguard.home_vpn[env(host)].private_key}}
    ' "$tmp/all.yaml" >"$tmp/$host.yaml"
  else
    host="$host" yq '{"wireguard": {"home_vpn": {env(host): {"private_key": .wireguard.home_vpn[env(host)].private_key}}}}' \
      "$tmp/all.yaml" >"$tmp/$host.yaml"
  fi
done

# Sanity checks before writing anything to the repository
leaves "$tmp/all.yaml" | grep -vx 'github_token' >"$tmp/expected"
for file in common "${hosts[@]}"; do leaves "$tmp/$file.yaml"; done | sort >"$tmp/actual"
if ! diff -q "$tmp/expected" "$tmp/actual" >/dev/null; then
  echo "[❌] The split does not match the original secrets (paths only):" >&2
  diff "$tmp/expected" "$tmp/actual" >&2 || true
  exit 1
fi
if grep -qx 'null' <(yq '.. | select(tag == "!!null")' "$tmp"/*.yaml); then
  echo "[❌] Some secret is missing (null) in the source; check the paths above" >&2
  exit 1
fi
echo "[✔️] $(wc -l <"$tmp/expected") secrets split into common + ${#hosts[@]} host files"

for file in common "${hosts[@]}"; do
  # --filename-override only selects the .sops.yaml rule; it is not read
  # shellcheck disable=SC2094
  sops encrypt --filename-override "secrets/$file.yaml" "$tmp/$file.yaml" >"secrets/$file.yaml"
  echo "   └─ secrets/$file.yaml: $(leaves "$tmp/$file.yaml" | wc -l) secrets"
done

git add secrets/*.yaml .sops.yaml
echo "[✔️] Done. Review with 'git status', deploy, then remove the old file:"
echo "    git rm secrets/secrets.yaml && scripts/update_sops.sh -c"
