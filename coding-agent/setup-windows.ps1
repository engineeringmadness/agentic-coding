#Requires -Version 7.0

<#
.SYNOPSIS
    Windows (PowerShell 7) port of coding-agent/Dockerfile.

.DESCRIPTION
    Installs, as individually chosen components: Herdr Desktop, GitHub CLI
    (plus the gh-stack extension), Agent Browser (headless Chrome),
    Command Code, Pi, the curated Pi extensions, and the global agent
    skills (installed as a single bundle).

    Each component is prompted for in turn; confirming installs it
    immediately before moving on to the next component.

    Prerequisites that must already be on PATH: git, node, npm, winget.
    Run from a normal (non-admin) PowerShell 7 shell.

.EXAMPLE
    pwsh -NoProfile -File .\coding-agent\setup-windows.ps1

.NOTES
    Optional installs are prompted for interactively. For non-interactive
    setups, preset any of these (y/yes or n/no):
      $env:INSTALL_HERDR, $env:INSTALL_GH, $env:INSTALL_AGENT_BROWSER,
      $env:INSTALL_COMMAND_CODE, $env:INSTALL_PI, $env:INSTALL_PI_EXTENSIONS,
      $env:INSTALL_SKILLS
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

function Write-Skipped {
    param([string]$Message)
    Write-Host ''
    Write-Host "    Skipping $Message" -ForegroundColor Yellow
}

# --- Prerequisites --------------------------------------------------------

Write-Step 'Checking prerequisites'
Assert-Command -Name 'git'  -WingetId 'Git.Git'
Assert-Command -Name 'node' -WingetId 'OpenJS.NodeJS.LTS'
Assert-Command -Name 'npm'  -WingetId 'OpenJS.NodeJS.LTS'
Write-Host '    OK: git, node, npm' -ForegroundColor Green

# --- 1. Herdr Desktop -----------------------------------------------------

Write-Step 'Herdr Desktop'
$InstallHerdr = Ask-YesNo -VariableName 'INSTALL_HERDR' -Prompt 'Install Herdr Desktop?' -Default 'y'
if ($InstallHerdr -eq 'y') {
    Invoke-CLI 'powershell -c "irm https://releases.herdr.dev/app/install.ps1 | iex"' {
        powershell -c "irm https://releases.herdr.dev/app/install.ps1 | iex"
    }
}
else {
    Write-Skipped 'Herdr Desktop'
}

# --- 2. GitHub CLI --------------------------------------------------------

Write-Step 'GitHub CLI'
$InstallGh = Ask-YesNo -VariableName 'INSTALL_GH' -Prompt 'Install GitHub CLI (including the gh-stack extension)?' -Default 'y'
if ($InstallGh -eq 'y') {
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
    Assert-Command -Name 'gh' -WingetId 'GitHub.cli'
    $ghExtensions = (& gh extension list 2>$null) -join "`n"
    if ($ghExtensions -match 'gh-stack') {
        Write-Host '    gh-stack already installed' -ForegroundColor Yellow
    }
    else {
        Invoke-CLI 'gh extension install github/gh-stack' { gh extension install github/gh-stack }
    }
}
else {
    Write-Skipped 'GitHub CLI'
}

# --- 3. Agent Browser -----------------------------------------------------

Write-Step 'Agent Browser'
$InstallAgentBrowser = Ask-YesNo -VariableName 'INSTALL_AGENT_BROWSER' -Prompt 'Install Agent Browser (including headless Chrome)?' -Default 'y'
if ($InstallAgentBrowser -eq 'y') {
    Invoke-CLI 'npm install -g agent-browser' {
        npm install -g --no-audit --no-fund agent-browser
    }
    Add-NpmGlobalToPath
    Invoke-CLI 'agent-browser install' { agent-browser install }
}
else {
    Write-Skipped 'Agent Browser'
}

# --- 4. Command Code ------------------------------------------------------

Write-Step 'Command Code'
$InstallCommandCode = Ask-YesNo -VariableName 'INSTALL_COMMAND_CODE' -Prompt 'Install Command Code?' -Default 'y'
if ($InstallCommandCode -eq 'y') {
    Invoke-CLI 'npm install -g command-code@latest' {
        npm install -g --no-audit --no-fund 'command-code@latest'
    }
    Add-NpmGlobalToPath
    if ($InstallHerdr -eq 'y') {
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
    }
}
else {
    Write-Skipped 'Command Code'
}

# --- 5. Pi ----------------------------------------------------------------

Write-Step 'Pi'
$InstallPi = Ask-YesNo -VariableName 'INSTALL_PI' -Prompt 'Install the Pi coding agent?' -Default 'y'
if ($InstallPi -eq 'y') {
    Invoke-CLI 'npm install -g @earendil-works/pi-coding-agent' {
        npm install -g --no-audit --no-fund '@earendil-works/pi-coding-agent'
    }
    Add-NpmGlobalToPath
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
else {
    Write-Skipped 'Pi'
}

# --- 6. Pi extensions -----------------------------------------------------

Write-Step 'Pi extensions'
$InstallPiExtensions = $null
if ($InstallPi -eq 'y') {
    $InstallPiExtensions = Ask-YesNo -VariableName 'INSTALL_PI_EXTENSIONS' -Prompt 'Install the curated set of Pi extensions?' -Default 'y'
    if ($InstallPiExtensions -eq 'y') {
        foreach ($pkg in $PiExtensions) {
            Invoke-CLI "pi install $pkg" { pi install $pkg }
        }
        Invoke-CLI 'pi list' { pi list }
    }
    else {
        Write-Skipped 'Pi extensions'
    }
}
else {
    Write-Skipped 'Pi extensions (Pi not installed)'
}

# --- 7. Agent skills (single bundle) --------------------------------------

Write-Step 'Agent skills'
$InstallSkills = Ask-YesNo -VariableName 'INSTALL_SKILLS' -Prompt 'Install the global agent skills bundle?' -Default 'y'
if ($InstallSkills -eq 'y') {
    foreach ($s in $Skills) {
        $source = $s.Source
        $skill  = $s.Skill
        Invoke-CLI "skills add $skill ($source)" {
            npx --yes skills add $source --skill $skill -g -a universal --copy -y
        }
    }
}
else {
    Write-Skipped 'Agent skills'
}

# --- Cleanup --------------------------------------------------------------

Write-Step 'Cleaning npm cache'
Invoke-CLI 'npm cache clean --force' { npm cache clean --force }

# --- Summary --------------------------------------------------------------

if ($InstallPiExtensions -eq 'y') {
    Write-Step 'Installed Pi extensions'
    Invoke-CLI 'pi list' { pi list }
}

if ($InstallSkills -eq 'y') {
    Write-Step 'Installed global skills'
    Invoke-CLI 'npx --yes skills list -g' { npx --yes skills list -g }
}

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
if ($InstallPi -eq 'y') {
    Write-Host 'Then start the agent with: pi'
}
else {
    Write-Host 'Pi was skipped. Set $env:INSTALL_PI=1 to install it later.'
}
