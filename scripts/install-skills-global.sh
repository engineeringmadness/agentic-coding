#!/usr/bin/env bash
# Install all skills from this repo globally (user directory), headlessly.
# Usage: ./install-skills-global.sh [owner/repo]
set -euo pipefail

REPO="${1:-engineeringmadness/agent-skills}"

if ! command -v npx >/dev/null 2>&1; then
  echo "Error: npx not found. Install Node.js (https://nodejs.org) first." >&2
  exit 1
fi

# --yes           : npx's own prompt to fetch the package
# --skill '*'     : every skill in the repo
# -g              : install to the user directory instead of the project
# -a universal    : install to the shared default location most agents read
# --copy          : real files instead of symlinks
export DISABLE_TELEMETRY=1
npx --yes skills add "$REPO" --skill '*' -g -a universal --copy -y
