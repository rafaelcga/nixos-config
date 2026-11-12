#!/usr/bin/env nix-shell
# shellcheck shell=bash
#!nix-shell --quiet -i bash -p coreutils gnugrep nix-update git

set -euo pipefail

REPO_DIR="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
PKGS_DIR="$REPO_DIR/pkgs"

# Configure Git for the automated commits
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"

echo "Committing pending changes (flake.lock, kernel) to bypass Nix lazy evaluation bug on dirty trees..."
git add "$REPO_DIR"
if ! git diff-index --quiet HEAD; then
  git commit -m "chore: pre-update changes"
fi

function has_custom_update() {
  local abs_path="$1"
  [[ "$(basename "$abs_path")" == "package.nix" && -f "$(dirname "$abs_path")/update.sh" ]]
}

function run_custom_update() {
  local abs_path="$1"
  echo "through custom script..."
  if (cd "$(dirname "$abs_path")" && ./update.sh); then
    echo "  [✔️] custom update succeeded"
    return 0
  else
    echo "  [❌] custom update failed"
    return 1
  fi
}

function run_nix_update() {
  local pkg_name="$1"

  (
    cd "$REPO_DIR" # nix-update needs to be launched on the flake's directory

    set +e
    local output # separate declaration and assignment for correct status capture
    output="$(nix-update "$pkg_name" --flake 2>&1)"
    local status=$?
    set -e

    local update_line
    update_line="$(grep -oP "Update \K\S+ -> \S+" <<<"$output" || true)"

    if [[ $status -eq 0 ]]; then
      if [[ -n "$update_line" ]]; then
        echo "[✔] updated: $update_line"
      else
        echo "[✔] up-to-date"
      fi
      return 0
    else
      echo "[❌] update failed:"
      echo "  ${output//$'\n'/$'\n'  }"
      return 1
    fi
  )
}

echo "Upgrading local packages..."

failed=0

while IFS= read -r abs_path; do
  pkg_name=$(basename "$(dirname "$abs_path")")

  printf "❖ %s " "$pkg_name"

  if has_custom_update "$abs_path"; then
    run_custom_update "$abs_path" || failed=1
  else
    run_nix_update "$pkg_name" || failed=1
  fi

  # Commit immediately to ensure a clean git tree for the next package's evaluation
  git add "$REPO_DIR"
  if ! git diff-index --quiet HEAD; then
    git commit -m "chore: update $pkg_name"
  fi

done < <(find "$PKGS_DIR" -type f -path "$PKGS_DIR/*/package.nix")

if [[ $failed -ne 0 ]]; then
  echo "❌ One or more package updates failed. Failing CI build."
  exit 1
fi
