@echo off
REM Mido Windows Batch Wrapper
REM This script runs Mido.sh via WSL on Windows

set SCRIPT_DIR=%~dp0
set MIDO_SH=%SCRIPT_DIR%Mido.sh

REM Check if WSL is available
where wsl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: WSL (Windows Subsystem for Linux) is not installed.
    echo Please install WSL first: https://docs.microsoft.com/en-us/windows/wsl/install
    echo.
    echo Alternatively, you can install Cygwin or MSYS2 and run Mido.sh directly.
    pause
    exit /b 1
)

REM Check if Mido.sh exists
if not exist "%MIDO_SH%" (
    echo ERROR: Mido.sh not found in %SCRIPT_DIR%
    pause
    exit /b 1
)

REM Run Mido.sh via WSL, passing all arguments
wsl bash "%MIDO_SH%" %*

REM Pause on error so user can see the message
if %ERRORLEVEL% NEQ 0 pause