@echo off
rem Install all skills from this repo globally (user directory), headlessly.
rem Usage: install-skills-global.bat [owner/repo]
setlocal

set "REPO=%~1"
if "%REPO%"=="" set "REPO=engineeringmadness/agent-skills"

where npx >nul 2>nul
if errorlevel 1 (
  echo Error: npx not found. Install Node.js first: https://nodejs.org
  exit /b 1
)

rem --yes: npx's own prompt to fetch the package
rem --skill "*": every skill in the repo
rem -g: install to the user directory instead of the project
rem -a universal: install to the shared default location most agents read
rem --copy: real files instead of symlinks (symlinks need admin/dev mode on Windows)
set "DISABLE_TELEMETRY=1"
npx --yes skills add "%REPO%" --skill "*" -g -a universal --copy -y
if errorlevel 1 (
  echo Skill installation failed.
  exit /b 1
)

echo Skills installed globally.
endlocal
