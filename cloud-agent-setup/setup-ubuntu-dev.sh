#!/usr/bin/env bash
# =============================================================================
# Ubuntu Developer Environment Setup
# Installs: Node.js 24 LTS, Miniconda (latest), Java 21, Git, htop, GitHub CLI, + coding agents (command-code, reasonix), + skills (brainstorming, caveman, java-design)
# Usage:   chmod +x setup-ubuntu-dev.sh && ./setup-ubuntu-dev.sh
# =============================================================================

set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── Helpers ─────────────────────────────────────────────────────────────────
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERR]${NC}   $*" >&2; }
header(){ echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"; echo -e "${GREEN}  $*${NC}"; echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"; }

require_sudo() {
  if ! sudo -n true 2>/dev/null; then
    info "This script needs sudo privileges. You may be prompted for your password."
    sudo -v
  fi
}

# Detect architecture for Miniconda download
detect_arch() {
  local arch
  arch=$(uname -m)
  case "$arch" in
    x86_64)  echo "x86_64" ;;
    aarch64) echo "aarch64" ;;
    *)       err "Unsupported architecture: $arch"; exit 1 ;;
  esac
}

# ── Pre-flight ──────────────────────────────────────────────────────────────
header "Ubuntu Developer Environment Setup"
info "Detecting system..."
info "Architecture: $(uname -m)"
info "Ubuntu version: $(lsb_release -rs 2>/dev/null || echo 'unknown')"
require_sudo

# ── 1. System Update & Essential Dependencies ───────────────────────────────
header "1/9  Updating system packages & installing dependencies"
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  wget

# Ensure Universe repository is enabled (needed for JDK on 22.04)
sudo add-apt-repository universe -y 2>/dev/null || true
sudo apt update -y

ok "System packages up to date"

# ── 2. Git ──────────────────────────────────────────────────────────────────
header "2/9  Installing Git"
if command -v git &>/dev/null; then
  ok "Git already installed: $(git --version)"
else
  sudo apt install -y git
  ok "Git installed: $(git --version)"
fi

# ── 3. Node.js 24 LTS (via NodeSource) ──────────────────────────────────────
header "3/9  Installing Node.js 24 LTS (Krypton)"
if command -v node &>/dev/null && node --version | grep -q '^v24\.'; then
  ok "Node.js 24 already installed: $(node --version)"
else
  NODE_MAJOR=24

  # Import NodeSource GPG key
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | sudo gpg --dearmor -o /usr/share/keyrings/nodesource.gpg --yes

  # Add NodeSource repository
  echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
    | sudo tee /etc/apt/sources.list.d/nodesource.list

  sudo apt update -y
  sudo apt install -y nodejs

  ok "Node.js installed: $(node --version)"
  ok "npm version: $(npm --version)"
fi

# ── 6. Java 21 (OpenJDK) ────────────────────────────────────────────────────
header "6/9  Installing Java 21 (OpenJDK)"
if command -v java &>/dev/null && java --version 2>&1 | grep -q '21\.'; then
  ok "Java 21 already installed: $(java --version 2>&1 | head -1)"
else
  sudo apt install -y openjdk-21-jdk
  ok "Java installed: $(java --version 2>&1 | head -1)"
fi

# Set JAVA_HOME
JAVA_HOME_PATH="/usr/lib/jvm/java-21-openjdk-$(detect_arch)"
if [ -d "$JAVA_HOME_PATH" ]; then
  if ! grep -q "JAVA_HOME" /etc/environment 2>/dev/null; then
    echo "JAVA_HOME=\"$JAVA_HOME_PATH\"" | sudo tee -a /etc/environment > /dev/null
    ok "JAVA_HOME set to $JAVA_HOME_PATH"
  else
    ok "JAVA_HOME already configured"
  fi
fi

# ── 7. htop ─────────────────────────────────────────────────────────────────
header "7/9  Installing htop"
if command -v htop &>/dev/null; then
  ok "htop already installed: $(htop --version 2>&1 | head -1)"
else
  sudo apt install -y htop
  ok "htop installed"
fi

# ── 8. GitHub CLI (gh) ──────────────────────────────────────────────────────
header "8/9  Installing GitHub CLI (gh)"
if command -v gh &>/dev/null; then
  ok "GitHub CLI already installed: $(gh --version 2>&1 | head -1)"
else
  info "Adding GitHub CLI APT repository..."

  sudo mkdir -p -m 755 /etc/apt/keyrings

  # Import GitHub's GPG key
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

  # Add GitHub CLI repository
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

  sudo apt update -y
  sudo apt install -y gh

  ok "GitHub CLI installed: $(gh --version 2>&1 | head -1)"
fi

# ── 9. Miniconda (latest) ───────────────────────────────────────────────────
header "9/9  Installing Miniconda (latest)"
if command -v conda &>/dev/null; then
  ok "Miniconda already installed: $(conda --version 2>&1)"
else
  ARCH=$(detect_arch)
  MINICONDA_SH="Miniconda3-latest-Linux-${ARCH}.sh"
  MINICONDA_URL="https://repo.anaconda.com/miniconda/${MINICONDA_SH}"

  info "Downloading Miniconda for ${ARCH}..."
  curl -fsSL -o "/tmp/${MINICONDA_SH}" "$MINICONDA_URL"

  info "Installing Miniconda (silent mode) to ~/miniconda3..."
  bash "/tmp/${MINICONDA_SH}" -b -p "$HOME/miniconda3"

  # Initialize conda for bash
  eval "$("$HOME/miniconda3/bin/conda" shell.bash hook)"
  conda init bash

  # Clean up
  rm -f "/tmp/${MINICONDA_SH}"

  ok "Miniconda installed to ~/miniconda3"
  ok "conda version: $($HOME/miniconda3/bin/conda --version)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
header "Installation Complete!"

echo ""
echo "  Installed versions:"
echo "  ───────────────────────────────────────────"
printf "  %-18s %s\n" "Git:"       "$(git --version 2>&1)"
printf "  %-18s %s\n" "Node.js:"   "$(node --version 2>&1)"
printf "  %-18s %s\n" "npm:"       "$(npm --version 2>&1)"
printf "  %-18s %s\n" "Java:"      "$(java --version 2>&1 | head -1)"
printf "  %-18s %s\n" "htop:"      "$(htop --version 2>&1 | head -1)"
printf "  %-18s %s\n" "GitHub CLI:" "$(gh --version 2>&1 | head -1)"
printf "  %-18s %s\n" "command-code:" "$(npm list -g command-code --depth=0 2>/dev/null | grep command-code@ | sed 's/.* //' || echo 'N/A')"
printf "  %-18s %s\n" "reasonix:"  "$(npm list -g reasonix --depth=0 2>/dev/null | grep reasonix@ | sed 's/.* //' || echo 'N/A')"
printf "  %-18s %s\n" "skills:"    "brainstorming, caveman, java-design"
printf "  %-18s %s\n" "conda:"     "$($HOME/miniconda3/bin/conda --version 2>&1 || echo 'restart shell')"
echo "  ───────────────────────────────────────────"
echo ""
echo -e "  ${YELLOW}⚠  Restart your shell (or run 'exec bash') for conda to be fully active.${NC}"
echo ""
