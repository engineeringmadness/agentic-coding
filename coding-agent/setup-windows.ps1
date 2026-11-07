#Requires -Version 7.0

<#
.SYNOPSIS
    Windows (PowerShell 7) port of coding-agent/Dockerfile.

.DESCRIPTION
    Installs the Pi coding agent and its extensions, Command Code, Herdr,
    the Command Code Herdr status mod, Agent Browser (headless Chrome),
    GitHub CLI, the gh-stack GitHub CLI extension, and the global agent skills.

    Prerequisites that must already be on PATH: git, node, npm, winget.
    Run from a normal (non-admin) PowerShell 7 shell.

.EXAMPLE
    pwsh -NoProfile -File .\coding-agent\setup-windows.ps1

.NOTES
    Optional installs are prompted for interactively. For non-interactive
    setups, preset any of these (y/yes or n/no):
      $env:INSTALL_PI, $env:INSTALL_PI_EXTENSIONS, $env:USE_STACKED_PRS
    Defaults (yes) apply when a variable is unset, including on a piped stdin.
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

$HerdrModRepo = 'https://github.com/engineeringmadness/commandcode-herdr-desktop-mod'
$HerdrModDir  = Join-Path $HOME '.commandcode-herdr-desktop-mod'

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

# Ask-YesNo <VariableName> <Prompt> <Default>
# Uses the named environment variable when already set (y/yes/1 or n/no/0);
# otherwise prompts on an interactive host and falls back to the default
# when input is redirected.
function Ask-YesNo {
    param(
        [Parameter(Mandatory)][string]$VariableName,
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Default = 'y'
    )
    $current = Get-Item "Env:$VariableName" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
    if ($current) {
        $normalized = $current.Trim().ToLowerInvariant()
        $answer = switch ($normalized) {
            'y' { 'y' } 'yes' { 'y' } '1' { 'y' } 'true' { 'y' }
            'n' { 'n' } 'no' { 'n' } '0' { 'n' } 'false' { 'n' }
            default { $null }
        }
        if ($answer) {
            Set-Item "Env:$VariableName" $answer
            return $answer
        }
        Write-Warning "Ignoring invalid $VariableName=$current (using default $Default)"
        $current = $null
    }
    $defaultLabel = if ($Default -eq 'y') { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        $reply = $null
        if ($host.UI.RawUI -and -not [Console]::IsInputRedirected) {
            $reply = Read-Host "$Prompt $defaultLabel"
        }
        $reply = ($reply ?? '').Trim().ToLowerInvariant()
        switch ($reply) {
            '' { $answer = $Default }
            'y' { $answer = 'y' } 'yes' { $answer = 'y' }
            'n' { $answer = 'n' } 'no' { $answer = 'n' }
            default {
                Write-Host 'Please answer y or n.'
                continue
            }
        }
        Set-Item "Env:$VariableName" $answer
        return $answer
    }
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

function Update-SessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:PATH = (@($machinePath, $userPath, $env:PATH) | Where-Object { $_ }) -join ';'
}

# --- Optional install choices ----------------------------------------------

Write-Step 'Optional installs'
$InstallPi = Ask-YesNo -VariableName 'INSTALL_PI' -Prompt 'Install the secondary Pi harness?' -Default 'y'
$InstallPiExtensions = $null
$UseStackedPrs = $null
if ($InstallPi -eq 'y') {
    $InstallPiExtensions = Ask-YesNo -VariableName 'INSTALL_PI_EXTENSIONS' -Prompt 'Install the curated set of Pi extensions?' -Default 'y'
}
else {
    Write-Host '    Skipping Pi and its extensions' -ForegroundColor Yellow
}
$UseStackedPrs = Ask-YesNo -VariableName 'USE_STACKED_PRS' -Prompt 'Do you want to use stacked PRs (gh-stack extension + skill)?' -Default 'y'

# --- GitHub CLI -----------------------------------------------------------

Write-Step 'Installing GitHub CLI'
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host '    gh already installed' -ForegroundColor Yellow
}
else {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "'winget' was not found on PATH. Install App Installer, then run: winget install --id GitHub.cli"
    }
    Invoke-CLI 'winget install --id GitHub.cli' {
        winget install --id GitHub.cli -e --accept-package-agreements --accept-source-agreements
    }
    Update-SessionPath
}

# --- Prerequisites --------------------------------------------------------

Write-Step 'Checking prerequisites'
Assert-Command -Name 'git'  -WingetId 'Git.Git'
Assert-Command -Name 'node' -WingetId 'OpenJS.NodeJS.LTS'
Assert-Command -Name 'npm'  -WingetId 'OpenJS.NodeJS.LTS'
Assert-Command -Name 'gh'   -WingetId 'GitHub.cli'
Write-Host '    OK: git, node, npm, gh' -ForegroundColor Green

# --- Global CLI tools -----------------------------------------------------

Write-Step 'Installing Command Code and Agent Browser (npm global)'
if ($InstallPi -eq 'y') {
    Invoke-CLI 'npm install -g agent-browser @earendil-works/pi-coding-agent command-code@latest' {
        npm install -g --no-audit --no-fund agent-browser '@earendil-works/pi-coding-agent' 'command-code@latest'
    }
}
else {
    Invoke-CLI 'npm install -g agent-browser command-code@latest' {
        npm install -g --no-audit --no-fund agent-browser 'command-code@latest'
    }
}
Add-NpmGlobalToPath

# --- Herdr ----------------------------------------------------------------

Write-Step 'Installing Herdr'
Invoke-CLI 'powershell -c "irm https://releases.herdr.dev/app/install.ps1 | iex"' {
    powershell -c "irm https://releases.herdr.dev/app/install.ps1 | iex"
}

# --- Herdr Command Code mod ------------------------------------------------

Write-Step 'Installing Herdr Command Code mod'
if (Test-Path (Join-Path $HerdrModDir '.git')) {
    Write-Host "    $HerdrModDir already cloned, pulling latest" -ForegroundColor Yellow
    Invoke-CLI "git -C $HerdrModDir pull --ff-only" { git -C $HerdrModDir pull --ff-only }
}
elseif (Test-Path $HerdrModDir) {
    throw "$HerdrModDir exists and is not a git clone. Move it aside and re-run."
}
else {
    Invoke-CLI "git clone $HerdrModRepo $HerdrModDir" { git clone $HerdrModRepo $HerdrModDir }
}
Invoke-CLI "command-code mods add -g $HerdrModDir" { command-code mods add -g $HerdrModDir }
Invoke-CLI 'command-code mods list' { command-code mods list }

# --- Pi configuration (must exist before pi install) ----------------------

if ($InstallPi -eq 'y') {
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
}

# --- Agent Browser (headless Chrome) --------------------------------------

Write-Step 'Installing Chrome for Agent Browser'
Invoke-CLI 'agent-browser install' { agent-browser install }

# --- Pi extensions --------------------------------------------------------

if ($InstallPi -eq 'y' -and $InstallPiExtensions -eq 'y') {
    Write-Step 'Installing Pi extensions'
    foreach ($pkg in $PiExtensions) {
        Invoke-CLI "pi install $pkg" { pi install $pkg }
    }
    Invoke-CLI 'pi list' { pi list }
}
elseif ($InstallPi -eq 'y') {
    Write-Host ''
    Write-Host '    Skipping Pi extensions' -ForegroundColor Yellow
}

# --- GitHub CLI extension -------------------------------------------------

if ($UseStackedPrs -eq 'y') {
    Write-Step 'Installing gh-stack GitHub CLI extension'
    $ghExtensions = (& gh extension list 2>$null) -join "`n"
    if ($ghExtensions -match 'gh-stack') {
        Write-Host '    gh-stack already installed' -ForegroundColor Yellow
    }
    else {
        Invoke-CLI 'gh extension install github/gh-stack' { gh extension install github/gh-stack }
    }
}
else {
    Write-Host ''
    Write-Host '    Skipping gh-stack GitHub CLI extension' -ForegroundColor Yellow
}

# --- Global skills --------------------------------------------------------

Write-Step 'Installing global agent skills'
foreach ($s in $Skills) {
    $source = $s.Source
    $skill  = $s.Skill
    if ($skill -eq 'gh-stack' -and $UseStackedPrs -ne 'y') {
        Write-Host "    Skipping $skill skill" -ForegroundColor Yellow
        continue
    }
    Invoke-CLI "skills add $skill ($source)" {
        npx --yes skills add $source --skill $skill -g -a universal --copy -y
    }
}

# --- Cleanup --------------------------------------------------------------

Write-Step 'Cleaning npm cache'
Invoke-CLI 'npm cache clean --force' { npm cache clean --force }

# --- Summary --------------------------------------------------------------

if ($InstallPi -eq 'y') {
    Write-Step 'Installed Pi extensions'
    Invoke-CLI 'pi list' { pi list }
}

Write-Step 'Installed global skills'
Invoke-CLI 'npx --yes skills list -g' { npx --yes skills list -g }

Write-Host ''
Write-Host 'Done. Command Code, Herdr, Herdr status mod, Agent Browser, GitHub CLI, and skills are installed.' -ForegroundColor Green
if ($InstallPi -eq 'y') {
    Write-Host 'Then start the agent with: pi'
}
else {
    Write-Host 'Pi was skipped. Set $env:INSTALL_PI=1 to install it later.'
}
