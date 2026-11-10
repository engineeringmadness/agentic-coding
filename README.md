# Dev Setup

## An Opinionated Agentic Coding setup

### ADE / Agent Multiplexer - Herdr Desktop

Herdr's new [Desktop app](https://herdr.dev/) is honestly beautiful and helps manage multiple parallel agents seamlessly.

### Primary Harness - CommandCode

A great extensible feature packed harness that comes with its own generous coding subscription plan.

### Secondary Harness - Pi

A minimalist harness that yields control to its user, highly extensible and fast.

### Tooling

- **GitHub CLI** - Repo operations, PRs, Issue management. Stacked PR support reduces cognitive load on human code reviewer.
- **Agent-browser** - Test UI changes E2E using a headless chrome browser. Much more token efficient compared to Playwright / Selenium.
- **Agentmail** - Mailbox for agents accessible via a CLI, giving each agent its own inbox and address.

### Agent Skills

Installed globally for all agents (`-a universal --copy`):

1. `brainstorming` - [engineeringmadness/dev-setup](https://github.com/engineeringmadness/dev-setup)
2. `ponytail` - [dietrichgebert/ponytail](https://github.com/dietrichgebert/ponytail)
3. `gh-cli` - [zlliang/skills](https://github.com/zlliang/skills)
4. `gh-stack` - [github/gh-stack](https://github.com/github/gh-stack)
5. `agent-browser` - [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser)
6. `shadcn` - [shadcn-ui/ui](https://github.com/shadcn-ui/ui)
7. `supabase` - [supabase/agent-skills](https://github.com/supabase/agent-skills)
8. `agentmail-cli` - [agentmail-to/agentmail-skills](https://github.com/agentmail-to/agentmail-skills)

### Windows (PowerShell 7)

Native install of Pi, Command Code, Herdr, the extensions, Agent Browser, Agentmail, the gh-stack extension, and global skills.
Assumes that NodeJS 24 & Git is pre-installed on the system
```powershell
pwsh -NoProfile -Command "irm https://raw.githubusercontent.com/engineeringmadness/agentic-coding/master/coding-agent/setup-windows.ps1 | iex"
```

### Linux (Bash)

Native install of Pi, Command Code, Herdr, the extensions, Agent Browser, Agentmail, the gh-stack extension, and global skills.
Assumes that NodeJS 24 & Git is pre-installed on the system
```bash
curl -fsSL https://raw.githubusercontent.com/engineeringmadness/agentic-coding/master/coding-agent/setup-linux.sh | bash
```
