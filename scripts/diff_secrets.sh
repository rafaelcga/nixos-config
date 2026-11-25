#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils git openssh sops wireguard-tools "python3.withPackages (p: [ p.pyyaml ])"

# Compares the secrets of two revisions without printing any value: for every
# secret, whether it changed, plus a format check of the known secret types
# (e.g. after a rotation). Asks for your SSH key passphrase only once.

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") [<old rev> [<new rev>]]"
  echo ""
  echo "Shows which secrets changed between two revisions (default: HEAD~1 and HEAD;"
  echo "use 'WORKTREE' as <new rev> for uncommitted changes). Values are never printed."
  exit 1
}

[[ "${1:-}" == -* ]] && usage
old_rev="${1:-HEAD~1}"
new_rev="${2:-HEAD}"

cd "$REPO_DIR"
umask 077
tmp="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/diff-secrets.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# sops prompts for the passphrase on every decryption: unlock a temporary copy
# of the key once instead (in a private tmpfs directory, removed on exit)
key="${SOPS_AGE_SSH_PRIVATE_KEY_FILE:-$HOME/.ssh/id_ed25519}"
if ! ssh-keygen -y -P "" -f "$key" >/dev/null 2>&1; then
  cp "$key" "$tmp/key"
  echo "Unlocking $key for this run..."
  ssh-keygen -q -p -N "" -f "$tmp/key" >/dev/null
  key="$tmp/key"
fi
export SOPS_AGE_SSH_PRIVATE_KEY_FILE="$key"

function decrypt() { # <rev> <file> <out>
  if [[ "$1" == WORKTREE ]]; then
    [[ -f "$2" ]] && sops decrypt "$2" >"$3" || echo "{}" >"$3"
  elif git cat-file -e "$1:$2" 2>/dev/null; then
    git show "$1:$2" >"$3.enc"
    sops decrypt --input-type yaml --output-type yaml "$3.enc" >"$3"
  else
    echo "{}" >"$3"
  fi
}

files=()
for file in $(
  {
    if [[ "$new_rev" == WORKTREE ]]; then
      ls secrets/*.yaml
    else
      git ls-tree --name-only "$new_rev" secrets/
    fi
    git ls-tree --name-only "$old_rev" secrets/
  } | grep -E '^secrets/[^/]+\.yaml$' | sort -u
); do
  name="$(basename "$file" .yaml)"
  decrypt "$old_rev" "$file" "$tmp/$name.old"
  decrypt "$new_rev" "$file" "$tmp/$name.new"
  files+=("$name")
done

echo "Secrets: $old_rev -> $new_rev"
python3 -I - "$tmp" "${files[@]}" <<'EOF'
import re, subprocess, sys, yaml

tmp, names = sys.argv[1], sys.argv[2:]

def leaves(node, prefix=()):
    if isinstance(node, dict):
        for key, value in node.items():
            yield from leaves(value, prefix + (str(key),))
    else:
        yield "/".join(prefix), "" if node is None else str(node)

def load(name, side):
    with open(f"{tmp}/{name}.{side}") as f:
        return dict(leaves(yaml.safe_load(f) or {}))

new = {n: load(n, "new") for n in names}
everything = {path: value for n in names for path, value in new[n].items()}

def wg_pubkey(private):
    out = subprocess.run(["wg", "pubkey"], input=private.encode(), capture_output=True)
    return out.stdout.decode().strip() if out.returncode == 0 else None

B64_KEY = r"[A-Za-z0-9+/]{43}="
CHECKS = [  # (path regex, value regex or callable, description)
    (r"porkbun/api_key", r"pk1_[A-Za-z0-9]{20,}", "pk1_…"),
    (r"porkbun/api_secret_key", r"sk1_[A-Za-z0-9]{20,}", "sk1_…"),
    (r"servarr/.*", r"[0-9a-f]{32}", "32 hex"),
    (r"wireguard/.*/(private|public)_key", B64_KEY, "WireGuard key"),
    (r"wireguard/proton/endpoint", r"[0-9.]+|[0-9a-fA-F:]+", "IP, no port"),
    (r"passwords/user", r"\$(y|gy|7|6|5|2[aby])\$.+", "crypt hash (mkpasswd)"),
    (r"qbittorrent/password_hash", r"@ByteArray\([A-Za-z0-9+/=]+:[A-Za-z0-9+/=]+\)", "@ByteArray(salt:hash)"),
    (r"adguard/password_hash", r"\$2[aby]\$\d\d\$.{53}", "bcrypt"),
    (r"rclone_proton_config", lambda v: "[proton]" in v and "type = protondrive" in v, "[proton] protondrive remote"),
]

def check(path, value):
    notes = []
    for path_re, rule, what in CHECKS:
        if re.fullmatch(path_re, path):
            ok = rule(value) if callable(rule) else re.fullmatch(rule, value) is not None
            notes.append(("ok " if ok else "BAD ") + what)
    # A WireGuard private key must match the public key stored for it
    m = re.fullmatch(r"(wireguard/home_vpn/[^/]+)/private_key", path)
    if m and f"{m.group(1)}/public_key" in everything:
        notes.append("ok pair" if wg_pubkey(value) == everything[f"{m.group(1)}/public_key"] else "BAD pair mismatch")
    return ", ".join(notes)

changed = 0
for name in names:
    old = load(name, "old")
    print(f"\n{name}.yaml")
    for path in sorted(set(old) | set(new[name])):
        if path not in new[name]:
            status, notes = "REMOVED", ""
        elif path not in old:
            status, notes = "ADDED", check(path, new[name][path])
        elif old[path] != new[name][path]:
            status, notes = "CHANGED", check(path, new[name][path])
        else:
            status, notes = "same", ""
        changed += status != "same"
        print(f"  {status:<8} {path:<42} {notes}")
print(f"\n{changed} secret(s) differ")
EOF
