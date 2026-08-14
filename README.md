# agent-skills

An [Agent Plugin](https://agent-plugins.org/) — a portable package of [Agent Skills](https://agentskills.io/specification) that any skills-capable agent client can discover and load.

## Structure

```
agent-skills/
├── plugin.json          # Agent Plugins manifest
└── skills/
    ├── dux4j/           # Dux4J state management for Java
    └── java-design/     # Java design principles (Venkat Subramaniam)
```

## Skills

1. **`dux4j`** — Build state-managed Java applications with [Dux4J](http://dux4j.netlify.app/), a Redux/Flux-style store for Java.
2. **`java-design`** — Write well-designed Java by applying Venkat Subramaniam's object-oriented and functional design principles.

## Installation

Install the whole plugin with any Agent Plugins-compatible client, or install individual skills:

```sh
# List all skills in the plugin
npx skills add https://github.com/engineeringmadness/agent-skills --list

# Install a specific skill
npx skills add https://github.com/engineeringmadness/agent-skills --skill name-of-skill
```
