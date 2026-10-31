#!/usr/bin/env bash

#
# Linux/macOS (Bash) port of coding-agent/Dockerfile.
#
# Installs the Pi coding agent and its extensions, Agent Browser (headless
# Chrome), GitHub CLI, the gh-stack GitHub CLI extension, and the global agent
# skills.
#
# Prerequisites on PATH: git, node, npm.
# Run from a normal (non-root) shell.
#
# Example:
#   bash ./coding-agent/setup-linux.sh
#

set -euo pipefail

# --- Configuration (mirrors the Dockerfile) -------------------------------

export NPM_CONFIG_UPDATE_NOTIFIER=false
export NPM_CONFIG_FUND=false
export PI_SKIP_VERSION_CHECK=1
export PI_TELEMETRY=0

PI_AGENT_DIR="$HOME/.pi/agent"
PI_SETTINGS="$PI_AGENT_DIR/settings.json"

PI_EXTENSIONS=(
    'npm:pi-goal-x'
    'npm:pi-subagents'
    'npm:pi-web-access'
    'npm:pi-cwd-guard'
    'npm:@luxass/pi-whimsical'
    'npm:pi-deepseek-cache'
    'npm:pi-plan'
    'npm:@tintinweb/pi-tasks'
    'npm:pi-tps-status'
    'npm:pi-ask-user-question'
)

SKILL_SOURCES=(
    'https://github.com/engineeringmadness/dev-setup'
    'https://github.com/dietrichgebert/ponytail'
    'https://github.com/zlliang/skills'
    'https://github.com/github/gh-stack'
    'https://github.com/vercel-labs/agent-browser'
    'shadcn/ui'
    'supabase/agent-skills'
)

SKILL_NAMES=(
    'brainstorming'
    'ponytail'
    'gh-cli'
    'gh-stack'
    'agent-browser'
    'shadcn'
    'supabase'
)

# --- Helpers --------------------------------------------------------------

if [ -t 1 ]; then
    CYAN=$'\033[36m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    GRAY=$'\033[90m'
    RESET=$'\033[0m'
else
    CYAN=''
    GREEN=''
    YELLOW=''
    GRAY=''
    RESET=''
fi

step() {
    printf '\n%s==> %s%s\n' "$CYAN" "$1" "$RESET"
}

run() {
    local description="$1"
    shift
    printf '    %s> %s%s\n' "$GRAY" "$description" "$RESET"
    if ! "$@"; then
        printf 'Command failed: %s\n' "$description" >&2
        exit 1
    fi
}

print_install_hint() {
    local name="$1"
    local pkg="$name"
    [ "$name" = 'node' ] && pkg='nodejs'

    if [ "$(uname -s)" = 'Darwin' ]; then
        [ "$name" = 'node' ] && pkg='node'
        printf 'Install it first: brew install %s\n' "$pkg" >&2
    elif command -v apt-get >/dev/null 2>&1; then
        printf 'Install it first: sudo apt-get install -y %s\n' "$pkg" >&2
    elif command -v dnf >/dev/null 2>&1; then
        printf 'Install it first: sudo dnf install -y %s\n' "$pkg" >&2
    elif command -v pacman >/dev/null 2>&1; then
        printf 'Install it first: sudo pacman -S %s\n' "$pkg" >&2
    else
        printf "Install '%s' with your system package manager.\n" "$name" >&2
    fi
}

assert_command() {
    local name="$1"
    if ! command -v "$name" >/dev/null 2>&1; then
        printf "Error: '%s' was not found on PATH.\n" "$name" >&2
        print_install_hint "$name"
        exit 1
    fi
}

add_npm_global_to_path() {
    local prefix
    prefix="$(npm config get prefix 2>/dev/null || true)"
    if [ -n "$prefix" ]; then
        case ":$PATH:" in
            *":$prefix:"*) ;;
            *) export PATH="$prefix:$PATH" ;;
        esac
    fi
}

install_gh() {
    if command -v gh >/dev/null 2>&1; then
        printf '    %sgh already installed%s\n' "$YELLOW" "$RESET"
        return
    fi

    local sudo=''
    if [ "$(id -u)" -ne 0 ]; then
        sudo='sudo'
    fi

    if [ "$(uname -s)" = 'Darwin' ]; then
        run 'brew install gh' brew install gh
        return
    fi

    if command -v apt-get >/dev/null 2>&1; then
        local keyring='/usr/share/keyrings/githubcli-archive-keyring.gpg'
        local tmp_key
        tmp_key="$(mktemp)"
        run 'download GitHub CLI apt key' curl -fsSL \
            https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "$tmp_key"
        run 'install GitHub CLI apt key' $sudo install -m 0644 "$tmp_key" "$keyring"
        rm -f "$tmp_key"
        run 'add GitHub CLI apt repository' $sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=$keyring] https://cli.github.com/packages stable main
EOF
        run 'apt-get update' $sudo apt-get update
        run 'apt-get install gh' $sudo apt-get install -y --no-install-recommends gh
    elif command -v dnf >/dev/null 2>&1; then
        run 'dnf install gh' $sudo dnf install -y gh
    elif command -v pacman >/dev/null 2>&1; then
        run 'pacman install github-cli' $sudo pacman -S --noconfirm github-cli
    else
        printf 'Cannot install GitHub CLI automatically. See: https://github.com/cli/cli#installation\n' >&2
        exit 1
    fi
}

# --- GitHub CLI -----------------------------------------------------------

step 'Installing GitHub CLI'
install_gh

# --- Prerequisites --------------------------------------------------------

step 'Checking prerequisites'
assert_command git
assert_command node
assert_command npm
assert_command gh
printf '    %sOK: git, node, npm, gh%s\n' "$GREEN" "$RESET"

# --- Global CLI tools -----------------------------------------------------

step 'Installing Pi coding agent and Agent Browser (npm global)'
run 'npm install -g agent-browser @earendil-works/pi-coding-agent' \
    npm install -g --no-audit --no-fund agent-browser '@earendil-works/pi-coding-agent'
add_npm_global_to_path

# --- Pi configuration (must exist before pi install) ----------------------

step "Configuring Pi ($PI_SETTINGS)"
mkdir -p "$PI_AGENT_DIR"
if [ ! -f "$PI_SETTINGS" ]; then
    cat > "$PI_SETTINGS" <<'EOF'
{
  "defaultProvider": "deepseek",
  "defaultModel": "deepseek-flash",
  "packages": []
}
EOF
    printf '    %sCreated %s%s\n' "$GREEN" "$PI_SETTINGS" "$RESET"
else
    printf '    %sKeeping existing %s%s\n' "$YELLOW" "$PI_SETTINGS" "$RESET"
fi

# --- Agent Browser (headless Chrome) --------------------------------------

step 'Installing Chrome for Agent Browser'
run 'agent-browser install' agent-browser install

# --- Pi extensions --------------------------------------------------------

step 'Installing Pi extensions'
for pkg in "${PI_EXTENSIONS[@]}"; do
    run "pi install $pkg" pi install "$pkg"
done
run 'pi list' pi list

# --- GitHub CLI extension -------------------------------------------------

step 'Installing gh-stack GitHub CLI extension'
if gh extension list 2>/dev/null | grep -q 'gh-stack'; then
    printf '    %sgh-stack already installed%s\n' "$YELLOW" "$RESET"
else
    run 'gh extension install github/gh-stack' gh extension install github/gh-stack
fi

# --- Global skills --------------------------------------------------------

step 'Installing global agent skills'
for i in "${!SKILL_NAMES[@]}"; do
    source="${SKILL_SOURCES[$i]}"
    skill="${SKILL_NAMES[$i]}"
    run "skills add $skill ($source)" \
        npx --yes skills add "$source" --skill "$skill" -g -a universal --copy -y
done

# --- Cleanup --------------------------------------------------------------

step 'Cleaning npm cache'
run 'npm cache clean --force' npm cache clean --force

# --- Summary --------------------------------------------------------------

step 'Installed Pi extensions'
run 'pi list' pi list

step 'Installed global skills'
run 'npx --yes skills list -g' npx --yes skills list -g

printf '\n%sDone. Pi, extensions, Agent Browser, GitHub CLI, gh-stack, and skills are installed.%s\n' "$GREEN" "$RESET"
printf 'Then start the agent with: pi\n'
