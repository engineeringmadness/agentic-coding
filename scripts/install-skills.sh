#!/usr/bin/env bash
# Install all skills from this repo into the current project, headlessly.
# Usage: ./install-skills.sh [owner/repo]
set -euo pipefail

REPO="${1:-engineeringmadness/agent-skills}"

if ! command -v npx >/dev/null 2>&1; then
  echo "Error: npx not found. Install Node.js (https://nodejs.org) first." >&2
  exit 1
fi

# --yes           : npx's own prompt to fetch the package
# --skill '*'     : every skill in the repo
# -a universal    : install to .agents/skills/, the shared default most agents read
# --copy          : real files instead of symlinks
export DISABLE_TELEMETRY=1
npx --yes skills add "$REPO" --skill '*' -a universal --copy -y
