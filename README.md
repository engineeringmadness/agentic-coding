# Software Factory

My Attempt to build a software factory using Open components as much as possiible

```
+-------------------+     +-------------------+
|   GitHub Issues   |     |  PRD from Notion  |
+---------+---------+     +---------+---------+
          |                         |
          +------------+------------+
                       |
                       V
|  +--------------------------------------------------------+  |
|  |               Codex CLI  (Coding Agent)                |  |
|  |                                                        |  |
|  |   [ Skills -- orchestrate the factory ]                |  |
|  |   [ agent-browser -- test a running web app ]          |  |
|  |   [ Node.js ]  [ Miniconda ]                           |  |
|  +--------------------------------------------------------+  |
|                                                              |
|  +------------------+                                        |
|  |   Happy daemon   |                                        |
|  +--------+---------+                                        |
            |
            |
            v
   +------------------+
   |   Mobile Phone   |
   +------------------+
```

## Installation

### Quick install All Skills

Install every skill in this repo in one line — no clone required, same as the OpenCode / Claude Code installers:

```sh
curl -fsSL https://raw.githubusercontent.com/engineeringmadness/agent-skills/master/scripts/install-skills-global.sh | bash
```

**Windows** (CMD — download and run the batch script):

```sh
curl -fsSL https://raw.githubusercontent.com/engineeringmadness/agent-skills/master/scripts/install-skills-global.bat | cmd
```

### Agent Skills

Install the whole plugin with any Agent Plugins-compatible client, or install individual skills:

```sh
# List all skills in the plugin
npx skills add https://github.com/engineeringmadness/agent-skills --list

# Install a specific skill
npx skills add https://github.com/engineeringmadness/agent-skills --skill name-of-skill
```

## Cloud Agent

A ready-to-use coding agent image is created that could be run locally or deployed in a cloud env:

### Build the image

```sh
docker build -t coding-agent .
```

### Create and run a container

Pass your API keys as environment variables and mount your project into `/workspace`:

```sh
docker run -d --name coding-agent -e DEEPSEEK_API_KEY=<key> -e GH_TOKEN=<token> -v "$(pwd):/workspace" coding-agent -c "tail -f /dev/null"
```

Attach to the running container when you want an interactive shell:

```sh
docker exec -it coding-agent bash
```
