FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
USER root

# Update system and install common server administration utilities
RUN apt-get update
RUN apt-get install -y sudo curl wget git ripgrep


# Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*


# GitHub CLI (latest, from the official apt repo)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
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
RUN npx skills add https://github.com/engineeringmadness/dev-setup --skill brainstorming -g -a universal --copy -y
RUN npx skills add https://github.com/engineeringmadness/dev-setup --skill java-design -g -a universal --copy -y
RUN npx skills add https://github.com/dietrichgebert/ponytail --skill ponytail -g -a universal --copy -y
RUN npx skills add https://github.com/zlliang/skills --skill gh-cli -g -a universal --copy -y
RUN npx skills add https://github.com/github/gh-stack --skill gh-stack -g -a universal --copy -y
RUN npx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser -g -a universal --copy -y

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
        npm:@tintinweb/pi-tasks \
        npm:pi-diet-ripgrep \
        npm:pi-ask-user-question \
    ; do \
        PI_SKIP_VERSION_CHECK=1 PI_TELEMETRY=0 pi install "$pkg"; \
    done; \
    pi list

RUN gh extension install github/gh-stack

# Auth is passed at runtime: -e DEEPSEEK_API_KEY=... -e GH_TOKEN=...
ENV DEEPSEEK_API_KEY=""
ENV GH_TOKEN=""

ENTRYPOINT ["/bin/bash"]
