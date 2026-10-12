<#
.SYNOPSIS
    Mido PowerShell Wrapper - Runs Mido.sh via WSL on Windows

.DESCRIPTION
    This script runs Mido.sh (a POSIX shell script for downloading Windows ISOs)
    via Windows Subsystem for Linux (WSL). It detects WSL availability and runs
    the script with all passed arguments.

.NOTES
    Requires WSL to be installed on Windows 10/11.
    See: https://docs.microsoft.com/en-us/windows/wsl/install
#>

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Args
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MidoSh = Join-Path $ScriptDir "Mido.sh"

# Check if WSL is available
if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Error "WSL (Windows Subsystem for Linux) is not installed."
    Write-Host "Please install WSL first: https://docs.microsoft.com/en-us/windows/wsl/install"
    Write-Host "Alternatively, install Cygwin or MSYS2 and run Mido.sh directly."
    exit 1
}

# Check if Mido.sh exists
if (-not (Test-Path $MidoSh)) {
    Write-Error "Mido.sh not found in $ScriptDir"
    exit 1
}

# Run Mido.sh via WSL with all arguments
$exitCode = wsl bash $MidoSh @Args

# Return the exit code from Mido.sh
exit $exitCode