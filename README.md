# agent-skills

An [Agent Plugin](https://agent-plugins.org/) and [Cursor Plugin](https://cursor.com/docs/plugins) — a portable package of [Agent Skills](https://agentskills.io/specification) that any skills-capable agent client can discover and load.

## Installation

### Quick install

Install every skill in this repo in one line — no clone required, same as the OpenCode / Claude Code installers:

**Project-local** (installs into the current project):

```sh
curl -fsSL https://raw.githubusercontent.com/engineeringmadness/agent-skills/master/scripts/install-skills.sh | bash
```

**Global** (installs into your user directory, available in every project):

```sh
curl -fsSL https://raw.githubusercontent.com/engineeringmadness/agent-skills/master/scripts/install-skills-global.sh | bash
```

**Windows** (CMD — download and run the batch script):

```sh
curl -fsSL https://raw.githubusercontent.com/engineeringmadness/agent-skills/master/scripts/install-skills.bat | cmd
```

**Global** (installs into your user directory, available in every project):

```sh
curl -fsSL https://raw.githubusercontent.com/engineeringmadness/agent-skills/master/scripts/install-skills-global.bat | cmd
```

### Agent Plugins (any compatible client)

Install the whole plugin with any Agent Plugins-compatible client, or install individual skills:

```sh
# List all skills in the plugin
npx skills add https://github.com/engineeringmadness/agent-skills --list

# Install a specific skill
npx skills add https://github.com/engineeringmadness/agent-skills --skill name-of-skill
```

## Skills

1. **`java-design`** — Write well-designed Java by applying Venkat Subramaniam's object-oriented and functional design principles.
2. **`brainstorming`** — Explore user intent, requirements, and design before any implementation. Sourced from [obra/superpowers](https://github.com/obra/superpowers) (MIT).
3. **`ponytail`** - The best code is the code never written. Sourced from [https://github.com/dietrichgebert/ponytail] (MIT)
4. **`gh-stack`** - Plugin for stacked PRs using Github CLI. Sourced from [https://github.com/github/gh-stack/tree/main/skills/gh-stack] (MIT)
5. **`software-factory`** - Overall orchestrator for the software factory process that instructs the agents to use the different skills at different steps of the factory lifecycle.