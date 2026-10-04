FROM node:24-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false \
    PI_SKIP_VERSION_CHECK=1 \
    PI_TELEMETRY=0

USER root

# System utilities + GitHub CLI
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        ripgrep \
        sudo \
        wget \
        ffmpeg \
        libx11-6 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 \
        libasound2 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 \
        libcairo2 libcups2 libdbus-1-3 libgbm1 libglib2.0-0 \
        libnspr4 libnss3 libpango-1.0-0 libxcb1 libxkbcommon0 \
        fonts-dejavu-core; \
    curl -fsSL \
        https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends gh; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Install global CLI tools
RUN npm install -g --no-audit --no-fund \
        agent-browser \
        @earendil-works/pi-coding-agent \
    && npm cache clean --force

WORKDIR /workspace

# VERY IMPORTANT:
# Pi uses ~/.pi/agent, so explicitly make HOME the agent user's home.
ENV HOME=/home/agent

# Create Pi configuration BEFORE installing packages.
# pi install will add package declarations to this file.
RUN mkdir -p "$HOME/.pi/agent" \
    && cat > "$HOME/.pi/agent/settings.json" <<'EOF'
{
  "defaultProvider": "deepseek",
  "defaultModel": "deepseek-flash",
  "packages": []
}
EOF

# Install Chrome for agent-browser as the same user who will run it.
RUN agent-browser install

# Install Pi packages/extensions.
# These declarations are persisted in ~/.pi/agent/settings.json.
RUN set -eux; \
    for pkg in \
        npm:pi-goal-x \
        npm:pi-subagents \
        npm:pi-web-access \
        npm:pi-mcp-adapter \
        npm:pi-deepseek-cache \
        npm:pi-plan \
        npm:@tintinweb/pi-tasks \
        npm:pi-diet-ripgrep \
        npm:pi-ask-user-question \
    ; do \
        pi install "$pkg"; \
    done; \
    pi list

# Install GitHub CLI extension for the agent user
RUN gh extension install github/gh-stack

# Global skills
RUN set -eux; \
    npx --yes skills add \
        https://github.com/engineeringmadness/dev-setup \
        --skill brainstorming -g -a universal --copy -y; \
    npx --yes skills add \
        https://github.com/engineeringmadness/dev-setup \
        --skill java-design -g -a universal --copy -y; \
    npx --yes skills add \
        https://github.com/dietrichgebert/ponytail \
        --skill ponytail -g -a universal --copy -y; \
    npx --yes skills add \
        https://github.com/zlliang/skills \
        --skill gh-cli -g -a universal --copy -y; \
    npx --yes skills add \
        https://github.com/github/gh-stack \
        --skill gh-stack -g -a universal --copy -y; \
    npx --yes skills add \
        https://github.com/vercel-labs/agent-browser \
        --skill agent-browser -g -a universal --copy -y; \
    npm cache clean --force

ENV DEEPSEEK_API_KEY="" \
    GH_TOKEN=""

ENTRYPOINT ["/bin/bash"]