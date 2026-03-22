@echo off
setlocal enabledelayedexpansion
title GandiWin Launcher
color 0A

:: Set BASEDIR (Rule 8.3)
set "BASEDIR=%~dp0"

:: PowerShell Detection (Section 7.1 - MANDATORY)
where powershell >nul 2>&1
if not errorlevel 1 (
    set "PS=powershell"
    goto :ps_found
)

where pwsh >nul 2>&1
if not errorlevel 1 (
    set "PS=pwsh"
    goto :ps_found
)

if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
    goto :ps_found
)

echo [ERROR] No PowerShell found!
pause
exit /b 1

:ps_found

:menu
cls
echo.
echo ========================================
echo   GANDIWIN POWER EDITION v3.0
echo ========================================
echo.
echo   [1] LAUNCH ALL TERMINALS
echo   [2] SYSTEM CHECK
echo   [3] UNIVERSAL MENU
echo   [4] LOG VIEWER
echo   [5] EXIT
echo.
echo ========================================
echo.

set /p CHOICE=  Enter choice: 

if "%CHOICE%"=="" goto :menu
if "%CHOICE%"=="1" goto :launch_all
if "%CHOICE%"=="2" goto :launch_system
if "%CHOICE%"=="3" goto :launch_menu
if "%CHOICE%"=="4" goto :launch_logs
if "%CHOICE%"=="5" exit
goto :menu

:launch_all
start "" %PS% -NoExit -ExecutionPolicy Bypass -File "%BASEDIR%system_check.ps1"
start "" %PS% -NoExit -ExecutionPolicy Bypass -File "%BASEDIR%universal_menu.ps1"
start "" %PS% -NoExit -ExecutionPolicy Bypass -File "%BASEDIR%log_viewer.ps1"
goto :menu

:launch_system
start "" %PS% -NoExit -ExecutionPolicy Bypass -File "%BASEDIR%system_check.ps1"
goto :menu

:launch_menu
start "" %PS% -NoExit -ExecutionPolicy Bypass -File "%BASEDIR%universal_menu.ps1"
goto :menu

:launch_logs
start "" %PS% -NoExit -ExecutionPolicy Bypass -File "%BASEDIR%log_viewer.ps1"
goto :menu
