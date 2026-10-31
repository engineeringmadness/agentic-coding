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
4. `pi-cwd-guard` - Safety guard for cwd access, protected paths, and common destructive commands
5. `@luxass/pi-whimsical` - Replace Pi's working message with rotating coding jokes, memes, and Star Wars references
6. `pi-deepseek-cache` - Ensure Deepseek caching is maximized by fixing cache prefixes
7. `pi-plan` - Add plan mode support
8. `@tintinweb/pi-tasks` - Add a TODO list tracker for multistep tasks
9. `pi-tps-status` - Tokens-per-second status widget with TTFT, token counts, and provider-usage reconciliation
10. `pi-ask-user-question` - Add interface for agent to ask clarifying questions in form of MCQs

### Skills

Installed globally for all agents (`-a universal --copy`):

1. `brainstorming` - [engineeringmadness/dev-setup](https://github.com/engineeringmadness/dev-setup)
2. `ponytail` - [dietrichgebert/ponytail](https://github.com/dietrichgebert/ponytail)
3. `gh-cli` - [zlliang/skills](https://github.com/zlliang/skills)
4. `gh-stack` - [github/gh-stack](https://github.com/github/gh-stack)
5. `agent-browser` - [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser)
6. `shadcn` - [shadcn-ui/ui](https://github.com/shadcn-ui/ui)
7. `supabase` - [supabase/agent-skills](https://github.com/supabase/agent-skills)

### Tooling

- **GitHub CLI** - Repo operations, PRs, Issue management. Stacked PR support reduces cognitive load on human code reviewer.
- **Agent-browser** - Test UI chanegs E2E using a headless chrome browser. Much more token efficient compared to Playwright / Selenium.

## Commands to Run

### Docker

```sh
docker run -d --name coding-agent -e DEEPSEEK_API_KEY=<key> -e GH_TOKEN=<token> -v "<location on disk where projects are stored>:/workspace" compscikaran/coding-agent:latest -c "tail -f /dev/null"
```

```sh
docker exec -it coding-agent bash
```

### Windows (PowerShell 7)

Native install of Pi, the extensions, Agent Browser, the gh-stack extension, and global skills.

```powershell
pwsh -NoProfile -Command "irm https://raw.githubusercontent.com/engineeringmadness/agentic-coding/master/coding-agent/setup-windows.ps1 | iex"
```
