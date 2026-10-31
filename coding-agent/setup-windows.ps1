#Requires -Version 7.0

<#
.SYNOPSIS
    Windows (PowerShell 7) port of coding-agent/Dockerfile.

.DESCRIPTION
    Installs the Pi coding agent and its extensions, Agent Browser (headless
    Chrome), the gh-stack GitHub CLI extension, and the global agent skills.

    Prerequisites that must already be on PATH: git, node, npm, gh.
    Run from a normal (non-admin) PowerShell 7 shell.

.EXAMPLE
    pwsh -NoProfile -File .\coding-agent\setup-windows.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$PSNativeCommandUseErrorActionPreference = $false

# --- Configuration (mirrors the Dockerfile) -------------------------------

$env:NPM_CONFIG_UPDATE_NOTIFIER = 'false'
$env:NPM_CONFIG_FUND           = 'false'
$env:PI_SKIP_VERSION_CHECK     = '1'
$env:PI_TELEMETRY              = '0'

$PiAgentDir = Join-Path $HOME '.pi\agent'
$PiSettings = Join-Path $PiAgentDir 'settings.json'

$PiExtensions = @(
    'npm:pi-goal-x'
    'npm:pi-subagents'
    'npm:pi-web-access'
    'npm:pi-cwd-guard'
    'npm:@luxass/pi-whimsical'
    'npm:pi-deepseek-cache'
    'npm:pi-plan'
    'npm:@tintinweb/pi-tasks'
    'npm:pi-tps-status'
    'npm:pi-ask-user-question'
)

$Skills = @(
    @{ Source = 'https://github.com/engineeringmadness/dev-setup'; Skill = 'brainstorming' }
    @{ Source = 'https://github.com/dietrichgebert/ponytail';      Skill = 'ponytail' }
    @{ Source = 'https://github.com/zlliang/skills';               Skill = 'gh-cli' }
    @{ Source = 'https://github.com/github/gh-stack';              Skill = 'gh-stack' }
    @{ Source = 'https://github.com/vercel-labs/agent-browser';    Skill = 'agent-browser' }
    @{ Source = 'shadcn/ui';                                       Skill = 'shadcn' }
    @{ Source = 'supabase/agent-skills';                           Skill = 'supabase' }
)

# --- Helpers --------------------------------------------------------------

function Write-Step {
    param([string]$Message)
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-CLI {
    param(
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][scriptblock]$Command
    )
    Write-Host "    > $Description" -ForegroundColor DarkGray
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit $LASTEXITCODE): $Description"
    }
}

function Assert-Command {
    param([string]$Name, [string]$WingetId)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "'$Name' was not found on PATH. Install it first with: winget install --id $WingetId -e"
    }
}

function Add-NpmGlobalToPath {
    $prefix = ([string](& npm config get prefix 2>$null)).Trim()
    if ($prefix -and ($env:PATH -split ';' -notcontains $prefix)) {
        $env:PATH = "$prefix;$env:PATH"
    }
}

# --- Prerequisites --------------------------------------------------------

Write-Step 'Checking prerequisites'
Assert-Command -Name 'git'  -WingetId 'Git.Git'
Assert-Command -Name 'node' -WingetId 'OpenJS.NodeJS.LTS'
Assert-Command -Name 'npm'  -WingetId 'OpenJS.NodeJS.LTS'
Assert-Command -Name 'gh'   -WingetId 'GitHub.cli'
Write-Host '    OK: git, node, npm, gh' -ForegroundColor Green

# --- Global CLI tools -----------------------------------------------------

Write-Step 'Installing Pi coding agent and Agent Browser (npm global)'
Invoke-CLI 'npm install -g agent-browser @earendil-works/pi-coding-agent' {
    npm install -g --no-audit --no-fund agent-browser '@earendil-works/pi-coding-agent'
}
Add-NpmGlobalToPath

# --- Pi configuration (must exist before pi install) ----------------------

Write-Step "Configuring Pi ($PiSettings)"
New-Item -ItemType Directory -Force -Path $PiAgentDir | Out-Null
if (-not (Test-Path $PiSettings)) {
    $settings = [ordered]@{
        defaultProvider = 'deepseek'
        defaultModel    = 'deepseek-flash'
        packages        = @()
    } | ConvertTo-Json -Depth 5
    Set-Content -Path $PiSettings -Value $settings -Encoding utf8
    Write-Host "    Created $PiSettings" -ForegroundColor Green
}
else {
    Write-Host "    Keeping existing $PiSettings" -ForegroundColor Yellow
}

# --- Agent Browser (headless Chrome) --------------------------------------

Write-Step 'Installing Chrome for Agent Browser'
Invoke-CLI 'agent-browser install' { agent-browser install }

# --- Pi extensions --------------------------------------------------------

Write-Step 'Installing Pi extensions'
foreach ($pkg in $PiExtensions) {
    Invoke-CLI "pi install $pkg" { pi install $pkg }
}
Invoke-CLI 'pi list' { pi list }

# --- GitHub CLI extension -------------------------------------------------

Write-Step 'Installing gh-stack GitHub CLI extension'
$ghExtensions = (& gh extension list 2>$null) -join "`n"
if ($ghExtensions -match 'gh-stack') {
    Write-Host '    gh-stack already installed' -ForegroundColor Yellow
}
else {
    Invoke-CLI 'gh extension install github/gh-stack' { gh extension install github/gh-stack }
}

# --- Global skills --------------------------------------------------------

Write-Step 'Installing global agent skills'
foreach ($s in $Skills) {
    $source = $s.Source
    $skill  = $s.Skill
    Invoke-CLI "skills add $skill ($source)" {
        npx --yes skills add $source --skill $skill -g -a universal --copy -y
    }
}

# --- Cleanup --------------------------------------------------------------

Write-Step 'Cleaning npm cache'
Invoke-CLI 'npm cache clean --force' { npm cache clean --force }

Write-Host ''
Write-Host 'Done. Pi, extensions, Agent Browser, gh-stack, and skills are installed.' -ForegroundColor Green
Write-Host 'Set these before launching Pi:'
Write-Host '    $env:DEEPSEEK_API_KEY = "<key>"'
Write-Host '    $env:GH_TOKEN         = "<token>"'
Write-Host 'Then start the agent with: pi'
