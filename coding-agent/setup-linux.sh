#!/usr/bin/env bash

#
# Linux/macOS (Bash) port of coding-agent/Dockerfile.
#
# Installs, as individually chosen components: Herdr Desktop, GitHub CLI
# (plus the gh-stack extension), Agent Browser (headless Chrome),
# Command Code, Pi, the curated Pi extensions, and the global agent
# skills (installed as a single bundle).
#
# Each component is prompted for in turn; confirming installs it
# immediately before moving on to the next component.
#
# Prerequisites on PATH: git, node, npm.
# Run from a normal (non-root) shell.
#
# Example:
#   bash ./coding-agent/setup-linux.sh
#
# Optional installs are prompted for interactively. For non-interactive
# setups, preset any of these (y/yes or n/no):
#   INSTALL_HERDR=1|0  INSTALL_GH=1|0  INSTALL_AGENT_BROWSER=1|0
#   INSTALL_COMMAND_CODE=1|0  INSTALL_PI=1|0
#   INSTALL_PI_EXTENSIONS=1|0  INSTALL_SKILLS=1|0
# Defaults (yes) apply when a variable is unset, including on a piped stdin.
#

set -euo pipefail

# --- Configuration (mirrors the Dockerfile) -------------------------------

export NPM_CONFIG_UPDATE_NOTIFIER=false
export NPM_CONFIG_FUND=false
export PI_SKIP_VERSION_CHECK=1
export PI_TELEMETRY=0

PI_AGENT_DIR="$HOME/.pi/agent"
PI_SETTINGS="$PI_AGENT_DIR/settings.json"

HERDR_MOD_REPO='https://github.com/engineeringmadness/commandcode-herdr-desktop-mod'
HERDR_MOD_DIR="$HOME/.commandcode-herdr-desktop-mod"

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

# ask_yes_no <VAR_NAME> <PROMPT> <DEFAULT>
# Uses $VAR_NAME when already set (y/yes/1 or n/no/0); otherwise prompts on a
# TTY and falls back to the default when stdin is not a terminal.
ask_yes_no() {
    local var="$1" prompt="$2" def="${3:-y}"
    local current="${!var:-}"
    if [ -n "$current" ]; then
        case "$current" in
            y|Y|yes|YES|1|true|TRUE) printf -v "$var" 'y' ;;
            n|N|no|NO|0|false|FALSE) printf -v "$var" 'n' ;;
            *) printf 'Warning: ignoring invalid %s=%s (using default %s)\n' "$var" "$current" "$def" >&2; printf -v "$var" '%s' "$def" ;;
        esac
        return
    fi
    if [ ! -t 0 ]; then
        printf -v "$var" '%s' "$def"
        return
    fi
    local reply=''
    while :; do
        if [ "$def" = 'y' ]; then
            printf '%s [Y/n] ' "$prompt"
        else
            printf '%s [y/N] ' "$prompt"
        fi
        IFS= read -r reply || reply=''
        reply="$(printf '%s' "$reply" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
        case "$reply" in
            ''|y|yes) printf -v "$var" 'y'; return ;;
            n|no) printf -v "$var" 'n'; return ;;
            *) printf 'Please answer y or n.\n' ;;
        esac
    done
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

install_gh_stack() {
    if gh extension list 2>/dev/null | grep -q 'gh-stack'; then
        printf '    %sgh-stack already installed%s\n' "$YELLOW" "$RESET"
    else
        run 'gh extension install github/gh-stack' gh extension install github/gh-stack
    fi
}

install_herdr_mod() {
    if [ -d "$HERDR_MOD_DIR/.git" ]; then
        printf '    %s%s already cloned, pulling latest%s\n' "$YELLOW" "$HERDR_MOD_DIR" "$RESET"
        run "git -C $HERDR_MOD_DIR pull --ff-only" git -C "$HERDR_MOD_DIR" pull --ff-only
    elif [ -e "$HERDR_MOD_DIR" ]; then
        printf 'Error: %s exists and is not a git clone. Move it aside and re-run.\n' "$HERDR_MOD_DIR" >&2
        exit 1
    else
        run "git clone $HERDR_MOD_REPO $HERDR_MOD_DIR" git clone "$HERDR_MOD_REPO" "$HERDR_MOD_DIR"
    fi
    run "command-code mods add -g $HERDR_MOD_DIR" command-code mods add -g "$HERDR_MOD_DIR"
    run 'command-code mods list' command-code mods list
}

configure_pi() {
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
}

skipped() {
    printf '\n    %sSkipping %s%s\n' "$YELLOW" "$1" "$RESET"
}

# --- Prerequisites --------------------------------------------------------

step 'Checking prerequisites'
assert_command git
assert_command node
assert_command npm
printf '    %sOK: git, node, npm%s\n' "$GREEN" "$RESET"

INSTALL_HERDR=''
INSTALL_GH=''
INSTALL_AGENT_BROWSER=''
INSTALL_COMMAND_CODE=''
INSTALL_PI=''
INSTALL_PI_EXTENSIONS=''
INSTALL_SKILLS=''

# --- 1. Herdr Desktop -----------------------------------------------------

step 'Herdr Desktop'
ask_yes_no INSTALL_HERDR 'Install Herdr Desktop?' y
if [ "$INSTALL_HERDR" = 'y' ]; then
    run 'curl -fsSL https://releases.herdr.dev/app/install.sh | sh' \
        sh -c 'curl -fsSL https://releases.herdr.dev/app/install.sh | sh'
else
    skipped 'Herdr Desktop'
fi

# --- 2. GitHub CLI --------------------------------------------------------

step 'GitHub CLI'
ask_yes_no INSTALL_GH 'Install GitHub CLI (including the gh-stack extension)?' y
if [ "$INSTALL_GH" = 'y' ]; then
    install_gh
    assert_command gh
    install_gh_stack
else
    skipped 'GitHub CLI'
fi

# --- 3. Agent Browser -----------------------------------------------------

step 'Agent Browser'
ask_yes_no INSTALL_AGENT_BROWSER 'Install Agent Browser (including headless Chrome)?' y
if [ "$INSTALL_AGENT_BROWSER" = 'y' ]; then
    run 'npm install -g agent-browser' \
        npm install -g --no-audit --no-fund agent-browser
    add_npm_global_to_path
    run 'agent-browser install' agent-browser install
else
    skipped 'Agent Browser'
fi

# --- 4. Command Code ------------------------------------------------------

step 'Command Code'
ask_yes_no INSTALL_COMMAND_CODE 'Install Command Code?' y
if [ "$INSTALL_COMMAND_CODE" = 'y' ]; then
    run 'npm install -g command-code@latest' \
        npm install -g --no-audit --no-fund 'command-code@latest'
    add_npm_global_to_path
    if [ "$INSTALL_HERDR" = 'y' ]; then
        step 'Herdr Command Code mod'
        install_herdr_mod
    fi
else
    skipped 'Command Code'
fi

# --- 5. Pi ----------------------------------------------------------------

step 'Pi'
ask_yes_no INSTALL_PI 'Install the Pi coding agent?' y
if [ "$INSTALL_PI" = 'y' ]; then
    run 'npm install -g @earendil-works/pi-coding-agent' \
        npm install -g --no-audit --no-fund '@earendil-works/pi-coding-agent'
    add_npm_global_to_path
    step "Configuring Pi ($PI_SETTINGS)"
    configure_pi
else
    skipped 'Pi'
fi

# --- 6. Pi extensions -----------------------------------------------------

step 'Pi extensions'
if [ "$INSTALL_PI" = 'y' ]; then
    ask_yes_no INSTALL_PI_EXTENSIONS 'Install the curated set of Pi extensions?' y
    if [ "$INSTALL_PI_EXTENSIONS" = 'y' ]; then
        for pkg in "${PI_EXTENSIONS[@]}"; do
            run "pi install $pkg" pi install "$pkg"
        done
        run 'pi list' pi list
    else
        skipped 'Pi extensions'
    fi
else
    skipped 'Pi extensions (Pi not installed)'
fi

# --- 7. Agent skills (single bundle) --------------------------------------

step 'Agent skills'
ask_yes_no INSTALL_SKILLS 'Install the global agent skills bundle?' y
if [ "$INSTALL_SKILLS" = 'y' ]; then
    for i in "${!SKILL_NAMES[@]}"; do
        skill="${SKILL_NAMES[$i]}"
        source="${SKILL_SOURCES[$i]}"
        run "skills add $skill ($source)" \
            npx --yes skills add "$source" --skill "$skill" -g -a universal --copy -y
    done
else
    skipped 'Agent skills'
fi

# --- Cleanup --------------------------------------------------------------

step 'Cleaning npm cache'
run 'npm cache clean --force' npm cache clean --force

# --- Summary --------------------------------------------------------------

if [ "$INSTALL_PI_EXTENSIONS" = 'y' ]; then
    step 'Installed Pi extensions'
    run 'pi list' pi list
fi

if [ "$INSTALL_SKILLS" = 'y' ]; then
    step 'Installed global skills'
    run 'npx --yes skills list -g' npx --yes skills list -g
fi

printf '\n%sDone.%s\n' "$GREEN" "$RESET"
if [ "$INSTALL_PI" = 'y' ]; then
    printf 'Then start the agent with: pi\n'
else
    printf 'Pi was skipped. Set INSTALL_PI=1 to install it later.\n'
fi
