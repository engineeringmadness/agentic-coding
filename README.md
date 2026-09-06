# agent-skills

An [Agent Plugin](https://agent-plugins.org/) and [Cursor Plugin](https://cursor.com/docs/plugins) — a portable package of [Agent Skills](https://agentskills.io/specification) that any skills-capable agent client can discover and load.

## Structure

```
agent-skills/
├── plugin.json              # Agent Plugins manifest (open standard)
├── .cursor-plugin/
│   └── plugin.json          # Cursor Plugin manifest
└── skills/
    ├── brainstorming/       # Idea → design workflow (from obra/superpowers)
    ├── dux4j/               # Dux4J state management for Java
    └── java-design/         # Java design principles (Venkat Subramaniam)
```

## Skills

1. **`dux4j`** — Build state-managed Java applications with [Dux4J](http://dux4j.netlify.app/), a Redux/Flux-style store for Java.
2. **`java-design`** — Write well-designed Java by applying Venkat Subramaniam's object-oriented and functional design principles.
3. **`brainstorming`** — Explore user intent, requirements, and design before any implementation. Sourced from [obra/superpowers](https://github.com/obra/superpowers) (MIT).

## Installation

### Cursor

Install as a Cursor plugin by cloning or symlinking into your local plugins directory:

```sh
# Clone into Cursor's local plugins directory
git clone https://github.com/engineeringmadness/agent-skills ~/.cursor/plugins/local/agent-skills
```

Then reload Cursor and enable the plugin under **Customize**.

You can also submit this repository to the [Cursor Marketplace](https://cursor.com/marketplace/publish).

### Agent Plugins (any compatible client)

Install the whole plugin with any Agent Plugins-compatible client, or install individual skills:

```sh
# List all skills in the plugin
npx skills add https://github.com/engineeringmadness/agent-skills --list

# Install a specific skill
npx skills add https://github.com/engineeringmadness/agent-skills --skill name-of-skill
```
