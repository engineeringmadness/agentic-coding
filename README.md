# Dev Setup

## An Opinionated Agentic Coding setup

### Harness - Pi

A minimalist harness that yields control to its user, highly extensible and fast

### Model - DeepSeek Flash V4.1 High

Once you get used to a 100-150 TPS rate in your coding agent you can never go back to Claude code (^_^!).
Deepseek is extremely cheap especially for cached inputs and the V4.1 Flash series has a very high token throuput rate.

### Extensions

1. `pi-goal-x` - Add /goal command for long running tasks with a clearly defined objective
2. `pi-subagents` - Add subagent support for code review, scouting codebases etc.
3. `pi-web-access` - Add web search tool for agent
4. `pi-mcp-adapter`- Add MCP support for common integrations like Notion, Parallel, Context7
5. `pi-plan` - Add plan mode support
6. `pi-tasks` - Add a TODO list tracker for multistep tasks
7. `pi-diet-ripgrep` - Add ripgrep tool 
8. `pi-ask-user-question` - Add interface for agent to ask claryfing questions in form of MCQs
9. `pi-deepseek-cache` - Ensure Deepseek caching is maximized by fixing cache prefixes

### Tooling

- **GitHub CLI** - Repo operations, PRs, Issue management. Stacked PR support reduces cognitive load on human code reviewer.
- **Agent-browser** - Test UI chanegs E2E using a headless chrome browser. Much more token efficient compared to Playwright / Selenium.
- **ripgrep** - Faster and more efficient `grep` alternative


## Commands to Run

```sh
docker run -d --name coding-agent -e DEEPSEEK_API_KEY=<key> -e GH_TOKEN=<token> -v "C:/Users/karan/Projects:/workspace" compscikaran/coding-agent:latest -c "tail -f /dev/null"
```

```sh
docker exec -it coding-agent bash
```
