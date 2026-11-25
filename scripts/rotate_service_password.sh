#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p sops "python3.withPackages (p: [ p.bcrypt ])"

# Sets the password shared by the qBittorrent and AdGuard web UIs. It lives in
# three secrets that must agree:
#   passwords/services          plain text, for the Homepage widgets
#   qbittorrent/password_hash   PBKDF2-SHA512 in qBittorrent's @ByteArray format
#   adguard/password_hash       bcrypt
# The password is read once from the terminal and only passed through stdin.

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
SECRETS_FILE="${1:-secrets/beelink.yaml}"

cd "$REPO_DIR"
if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "[❌] $SECRETS_FILE not found" >&2
  exit 1
fi

python3 -I - "$SECRETS_FILE" <<'EOF'
import base64, getpass, hashlib, json, os, subprocess, sys
import bcrypt

secrets_file = sys.argv[1]
password = getpass.getpass("New service password: ")
if password != getpass.getpass("Repeat it: "):
    sys.exit("[❌] Passwords don't match")
if len(password) < 16:
    sys.exit("[❌] Use at least 16 characters (a password manager can generate one)")

# qBittorrent >= 4.2: PBKDF2-HMAC-SHA512, 100000 iterations, 16-byte salt
salt = os.urandom(16)
digest = hashlib.pbkdf2_hmac("sha512", password.encode(), salt, 100_000)
qbittorrent = "@ByteArray({}:{})".format(
    base64.b64encode(salt).decode(), base64.b64encode(digest).decode()
)
adguard = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=10)).decode()

for path, value in [
    ('["passwords"]["services"]', password),
    ('["qbittorrent"]["password_hash"]', qbittorrent),
    ('["adguard"]["password_hash"]', adguard),
]:
    subprocess.run(
        ["sops", "set", "--value-stdin", secrets_file, path],
        input=json.dumps(value).encode(),
        check=True,
    )
    print(f"[✔️] Updated {path}")
EOF
