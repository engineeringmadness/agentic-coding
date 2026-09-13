FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

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

# Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Codex CLI
RUN npm install -g @openai/codex

# agent-browser
RUN npm install -g agent-browser

# Happy Coder
RUN npm install -g happy

# Notion CLI
RUN curl -fsSL https://ntn.dev | bash


# Miniconda (latest) into /opt/miniconda3, base env on PATH
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
        -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/miniconda3 \
    && rm /tmp/miniconda.sh \
    && /opt/miniconda3/bin/conda clean -afy
ENV PATH=/opt/miniconda3/bin:$PATH

# Non-root agent user
RUN useradd -m -s /bin/bash agent
USER agent
WORKDIR /workspace

# Codex CLI configured for DeepSeek V4.1 Flash (key passed at runtime via DEEPSEEK_API_KEY)
COPY --chown=agent:agent codex-config.toml /home/agent/.codex/config.toml
COPY --chown=agent:agent models.json /home/agent/.codex/models.json

# Global skills install from this repo (into agent's home, shared universal location)
RUN curl -fsSL https://raw.githubusercontent.com/engineeringmadness/agent-skills/master/scripts/install-skills-global.sh | bash

# Auth is passed at runtime: -e DEEPSEEK_API_KEY=... -e GH_TOKEN=...
ENV DEEPSEEK_API_KEY=""
ENV GH_TOKEN=""

ENTRYPOINT ["/bin/bash"]
