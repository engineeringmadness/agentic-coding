# Dev Setup

## An Opinionated Coding Agent Setup

- Runtimes - NodeJS, JDK, Miniconda
- PRD source - [Notion via MCP](https://developers.notion.com/guides/mcp/get-started-with-mcp)
- Issue Tracker - GitHub Issues
- Version Control - Github via [gh CLI](https://cli.github.com/) + [stack PR extension](https://docs.github.com/en/pull-requests/get-started/stacked-prs-quickstart)
- UI testing using [agent-browser](https://agent-browser.dev/)

## Agent Stack
- Pi Agent (base)
- Opinionated list of pi extensions
- Deepseek V4.1 flash model

## Build

```sh
docker build -t compscikaran/<image_name>:latest .
```

### Create and run a container

```sh

docker run -d --name linux-lab -v "C:/Users/karan/Projects/data:/home/student" compscikaran/linuxlab:latest -c "tail -f /dev/null"


docker run -d --name coding-agent -e DEEPSEEK_API_KEY=<key> -e GH_TOKEN=<token> -v "C:/Users/karan/Projects:/workspace" compscikaran/coding-agent:latest -c "tail -f /dev/null"
```

Attach to the running container when you want an interactive shell:

```sh
docker exec -it linux-lab bash
```
