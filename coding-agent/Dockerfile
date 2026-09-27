FROM compscikaran/linuxlab:latest

ENV DEBIAN_FRONTEND=noninteractive

USER root

# Base tools + GitHub CLI (latest, from the official apt repo)
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        bash-completion \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# agent-browser
RUN npm install -g agent-browser
RUN agent-browser install

# pi coding agent
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Non-root agent user
RUN useradd -m -s /bin/bash agent
USER agent
WORKDIR /workspace

# Global skills install from this repo (into agent's home, shared universal location)
RUN curl -fsSL https://raw.githubusercontent.com/engineeringmadness/agent-skills/master/scripts/install-skills-global.sh | bash

# Default to DeepSeek Flash; authenticates with the DEEPSEEK_API_KEY from the runtime env
RUN mkdir -p ~/.pi/agent && cat > ~/.pi/agent/settings.json <<'EOF'
{
  "defaultProvider": "deepseek",
  "defaultModel": "deepseek-flash"
}
EOF

# Pi extensions/packages (rewrites ~/.pi/agent/settings.json, keeping the defaults above)
RUN set -eu; \
    for pkg in \
        npm:pi-goal-x \
        npm:pi-subagents \
        npm:pi-web-access \
        npm:pi-mcp-adapter \
        npm:pi-deepseek-cache \
        npm:pi-plan \
        npm:pi-dynamic-workflows \
        npm:pi-ask-user-question \
    ; do \
        PI_SKIP_VERSION_CHECK=1 PI_TELEMETRY=0 pi install "$pkg"; \
    done; \
    pi list

# Auth is passed at runtime: -e DEEPSEEK_API_KEY=... -e GH_TOKEN=...
ENV DEEPSEEK_API_KEY=""
ENV GH_TOKEN=""

ENTRYPOINT ["/bin/bash"]
