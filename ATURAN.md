# GANDIWIN v3.0 - POWER EDITION

## Strict Development Guidelines & Architecture Specification

---

## ⚠️ DOKUMENTASI WAJIB BACA

Dokumen ini adalah **ATURAN KERAS** yang harus diikuti saat mengembangkan, memodifikasi, atau menambahkan fitur ke GandiWin. **Jangan pernah menyimpang** dari spesifikasi ini.

---

## 1. TARGET OS & MINIMUM REQUIREMENT

### 1.1 Target Utama (PRIMARY)

| OS             | Architecture    | Status          | Priority |
| -------------- | --------------- | --------------- | -------- |
| **Windows 10** | 32-bit & 64-bit | ✅ FULL SUPPORT | P0       |
| **Windows 11** | 64-bit only     | ✅ FULL SUPPORT | P0       |

### 1.2 Minimum Requirement (HARD REQUIREMENT)

```
OS:         Windows 10 Build 19041+ (2004) atau Windows 11
PowerShell: Version 5.1+ (PowerShell 5.x, BUKAN PowerShell 7)
Execution:  Must support -ExecutionPolicy Bypass
RAM:        4 GB minimum
Storage:    100 MB free space
Permission: Administrator recommended (not mandatory)
```

### 1.3 Fallback / Optional (LOW PRIORITY)

| OS                | Architecture | Status     | Notes                             |
| ----------------- | ------------ | ---------- | --------------------------------- |
| **Windows 7**     | 32/64-bit    | ⚠️ LIMITED | CMD basic features only           |
| **Windows 8/8.1** | 32/64-bit    | ❌ SKIP    | Tidak didukung, maintenance ribet |

### 1.4 PowerShell Version Check

```powershell
# WAJIB ada di setiap script utama
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    pause
    exit 1
}
```

---

## 2. APLIKASI VERSI & ARSITEKTUR

### 2.1 Language Stack

```
PRIMARY:   PowerShell 5.1 (.ps1 files)
BOOTSTRAP: Batch script (.bat) untuk launcher
NO:        VBScript, JavaScript, C#, .NET assemblies
```

### 2.2 Execution Model

```
✅ FULL PowerShell untuk semua 30 fitur
✅ Modular: 1 fitur = 1 file .ps1 terpisah
✅ Logging terstruktur ke folder logs/
✅ Multi-terminal architecture
✅ Interactive menu dengan hacker-style UI
```

### 2.3 Terminal Architecture (4 TERMINALS)

```
┌─────────────────────────────────────────────────────────┐
│ Terminal 1: system_check.ps1                            │
│ - Hardware/Software overview                            │
│ - Thermal, CPU, RAM, GPU, Storage, OS info              │
│ - Color: Green                                          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Terminal 2: universal_menu.ps1                          │
│ - Interactive menu 30 features                          │
│ - Launch features in new terminals                      │
│ - Color: Cyan                                           │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Terminal 3: log_viewer.ps1                              │
│ - Read all feature logs                                 │
│ - Export, clear, live monitor                           │
│ - Color: Yellow                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Terminal 4: Feature execution (dynamic)                 │
│ - Each feature runs in separate terminal                │
│ - Auto-close after completion or wait for user          │
│ - Color: Based on category                              │
└─────────────────────────────────────────────────────────┘
```

---

## 3. STRUKTUR FOLDER (HARD STRUCTURE)

### 3.1 Root Directory

```
GandiWin/
│
├── launcher.bat                  # MUST: Bootstrap launcher
├── system_check.ps1              # MUST: Hardware info terminal
├── universal_menu.ps1            # MUST: Main menu 30 features
├── log_viewer.ps1                # MUST: Log monitoring
│
├── features/                     # MUST: Feature modules folder
│   ├── 1_thermal_check/
│   │   └── 1_thermal_check.cmd
│   ├── 2_antivirus_conflict/
│   │   └── 2_antivirus_conflict.cmd
│   ├── 3_bloatware_removal/
│   │   └── 3_bloatware_removal.cmd
│   └── ... (30 folders total)
│
├── modules/                      # OPTIONAL: PowerShell helper modules
│   └── *.psm1
│
└── logs/                         # AUTO-CREATED: All logs
    ├── tweak_activity.log        # Main activity log
    ├── system_check.log          # System reports
    └── export_*.txt              # Exported logs
```

### 3.2 Feature Folder Naming Convention

```
FORMAT: {number}_{slug_name}/
EXAMPLE:
  1_thermal_check/
  2_antivirus_conflict/
  3_bloatware_removal/
  ...
  30_game_mode_bar/

RULES:
  - Number MUST be 1-30 (no leading zeros in folder name)
  - Slug MUST be lowercase with underscores
  - Script file MUST match folder name with .cmd extension
```

### 3.3 Script File Naming

```
INSIDE features/{number}_{slug}/:
  {number}_{slug}.cmd    # Main feature script (Windows PowerShell compatible)

NOT ALLOWED:
  - .ps1 inside features/ (use .cmd for compatibility)
  - Multiple scripts per feature folder
  - Uppercase in filenames
```

---

## 4. WORKFLOW & TERMINAL BEHAVIOR

### 4.1 Launcher Workflow

```
1. User runs launcher.bat
2. Launcher detects PowerShell (powershell.exe or pwsh.exe)
3. User selects option from menu
4. Selected terminal opens with -NoExit -ExecutionPolicy Bypass
5. Terminal stays open after script completion
6. User must manually close or press key to exit
```

### 4.2 Terminal Launch Command (STRICT FORMAT)

```batch
# CORRECT - Use this format:
start "" powershell.exe -NoExit -ExecutionPolicy Bypass -File "%BASEDIR%script.ps1"

# OR with inline command:
start "" powershell.exe -NoExit -ExecutionPolicy Bypass -Command "& { cd '%BASEDIR%'; .\script.ps1 }"

# WRONG - Never use:
powershell -File script.ps1              # Missing -NoExit, will close
start powershell.exe script.ps1          # Missing ExecutionPolicy
Invoke-Expression script.ps1             # Wrong execution method
```

### 4.3 Feature Execution Flow

```
1. User selects feature number (1-30) in universal_menu.ps1
2. Script constructs path: features/{number}_{slug}/{number}_{slug}.cmd
3. Launch with: Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "$ScriptPath"
4. Log activity: Log-Activity "TWEAK INITIATED: #N - Feature Name"
5. Feature runs in NEW terminal window
6. Universal menu stays open and responsive
```

---

## 5. 30 FEATURES SPECIFICATION

### 5.1 Feature List with Slug & Category

| #   | Feature Name          | Folder Slug                | Category    | Color    |
| --- | --------------------- | -------------------------- | ----------- | -------- |
| 01  | Thermal Check         | `1_thermal_check`          | PERFORMANCE | Green    |
| 02  | Antivirus Conflict    | `2_antivirus_conflict`     | PERFORMANCE | Green    |
| 03  | Bloatware Removal     | `3_bloatware_removal`      | PERFORMANCE | Green    |
| 04  | Startup Control       | `4_startup_control`        | PERFORMANCE | Green    |
| 05  | Background Services   | `5_background_services`    | PERFORMANCE | Green    |
| 06  | Background Apps       | `6_background_apps`        | PERFORMANCE | Green    |
| 07  | Telemetry Disabler    | `7_telemetry_disabler`     | PRIVACY     | Blue     |
| 08  | Delivery Optimization | `8_delivery_optimization`  | PRIVACY     | Blue     |
| 09  | Scheduled Tasks       | `9_scheduled_tasks`        | PRIVACY     | Blue     |
| 10  | Disk Cleanup          | `10_disk_cleanup`          | PRIVACY     | Blue     |
| 11  | NTFS Repair           | `11_ntfs_repair`           | MAINTENANCE | Magenta  |
| 12  | AppData Cleanup       | `12_appdata_cleanup`       | MAINTENANCE | Magenta  |
| 13  | Ghost Drivers         | `13_ghost_drivers`         | MAINTENANCE | Magenta  |
| 14  | Hibernation Disable   | `14_hibernation_disable`   | MAINTENANCE | Magenta  |
| 15  | Virtual Memory        | `15_virtual_memory`        | MAINTENANCE | Magenta  |
| 16  | Spectre Meltdown      | `16_spectre_meltdown`      | SECURITY    | Red      |
| 17  | CPU Core Unparking    | `17_cpu_core_unparking`    | SECURITY    | Red      |
| 18  | MSI Mode Interrupt    | `18_msi_mode_interrupt`    | SECURITY    | Red      |
| 19  | Network Throttling    | `19_network_throttling`    | SECURITY    | Red      |
| 20  | GPU HAGS              | `20_gpu_hags`              | GAMING      | Yellow   |
| 21  | Nagle Algorithm       | `21_nagle_algorithm`       | GAMING      | Yellow   |
| 22  | Visual Effects        | `22_visual_effects`        | GAMING      | Yellow   |
| 23  | Power Plan            | `23_power_plan`            | GAMING      | Yellow   |
| 24  | USB Selective Suspend | `24_usb_selective_suspend` | GAMING      | Yellow   |
| 25  | Mouse Precision       | `25_mouse_precision`       | GAMING      | Yellow   |
| 26  | Shell Extensions      | `26_shell_extensions`      | UI          | DarkCyan |
| 27  | Explorer Quick Access | `27_explorer_quick_access` | UI          | DarkCyan |
| 28  | Indexing Service      | `28_indexing_service`      | UI          | DarkCyan |
| 29  | Registry Optimization | `29_registry_optimization` | UI          | DarkCyan |
| 30  | Game Mode Bar         | `30_game_mode_bar`         | UI          | DarkCyan |

### 5.2 Feature Script Template (MANDATORY)

```batch
@echo off
title GANDIWIN :: FEATURE_NAME
color 0A

set "BASEDIR=%~dp0"
set "LogsDir=%BASEDIR%..\logs"
set "ActivityLog=%LogsDir%\tweak_activity.log"

if not exist "%LogsDir%" mkdir "%LogsDir%"

echo.
echo ========================================
echo   FEATURE_NAME - Description
echo ========================================
echo.

:: Feature logic here
echo [*] Running feature...

:: Log activity
echo [%DATE% %TIME%] FEATURE_NAME: Executed >> "%ActivityLog%"

echo.
echo ========================================
echo   Complete!
echo ========================================
echo.
pause
exit /b 0
```

---

## 6. STRICT SCRIPT RULES & SAFETY

### 6.1 Execution Policy (NON-NEGOTIABLE)

```
ALWAYS use: -ExecutionPolicy Bypass
NEVER use: -ExecutionPolicy Unrestricted (security risk)
NEVER use: Set-ExecutionPolicy permanently (temporary only)
```

### 6.2 Terminal Behavior

```
ALWAYS: -NoExit flag (terminal stays open)
ALWAYS: pause before exit (user must acknowledge)
NEVER: exit /b without pause (user can't see result)
NEVER: Close-Host in scripts (kills terminal)
```

### 6.3 Logging Requirements

```powershell
# EVERY feature MUST log:
function Log-Activity {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] $Message" | Out-File -FilePath $ActivityLog -Append -Encoding UTF8
}

# Log at minimum:
Log-Activity "TWEAK INITIATED: #N - Feature Name"
Log-Activity "TWEAK COMPLETE: #N - Feature Name"
Log-Activity "ERROR: #N - Error description"  # If error occurs
```

### 6.4 Input Validation

```powershell
# Menu input MUST validate:
$Choice = Read-Host "  Enter choice (1-30)"

if ($Choice -match "^\d+$") {
    $Num = [int]$Choice
    if ($Num -lt 1 -or $Num -gt 30) {
        Write-Host "  [!] Invalid: Enter 1-30" -ForegroundColor Red
        Start-Sleep -Seconds 1
        goto MainMenu
    }
} else {
    Write-Host "  [!] Invalid: Numbers only" -ForegroundColor Red
    Start-Sleep -Seconds 1
    goto MainMenu
}
```

### 6.5 Error Handling

```powershell
# EVERY operation that can fail MUST have:
try {
    # Risky operation
    Get-ItemProperty -Path "HKLM:\..." -ErrorAction Stop
} catch {
    Write-Host "  [X] ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Log-Activity "ERROR: Feature Name - $($_.Exception.Message)"
    pause
    exit 1
}
```

### 6.6 Cross-Version Safety

```powershell
# Check PowerShell version before using modern cmdlets
if ($PSVersionTable.PSVersion.Major -ge 5) {
    # PowerShell 5+ features
    Get-CimInstance Win32_OperatingSystem
} else {
    # Fallback for older PowerShell
    Get-WmiObject Win32_OperatingSystem
}

# Check OS version before OS-specific tweaks
$OSBuild = [Environment]::OSVersion.Version.Build
if ($OSBuild -ge 22000) {
    # Windows 11 specific
} elseif ($OSBuild -ge 19041) {
    # Windows 10 specific
}
```

### 6.7 UI/UX Standards (HACKER-STYLE)

```
MANDATORY UI MODULE (GandiWinUI.psm1):
  ✅ ALL terminal styling must use `Import-Module "$PSScriptRoot\modules\GandiWinUI.psm1"`
  ✅ Setup terminal: `Set-GandiConsole -Title "..."` (Auto-forces Consolas 18 via P/Invoke)
  ✅ Main Banners: `Show-GandiBanner` (For Control Center & Log Viewer)
  ✅ Module Headers: `Show-GandiHeader -Title "..."` (For the 30 individual features)
  ✅ Info Boxes: `Show-GandiBox`, `Show-GandiKeyValue`
  ✅ Status Logs: `Write-GandiStatus -Status "OK|FAIL|WARN|INFO|WAIT" -Message "..."`
  ✅ Emphasized Text: `Invoke-GandiTypewriter -Text "..."`
  ❌ NO custom `Show-Header`, `Show-Section`, or manual `Write-Host` spaghetti.

ALLOWED CHARACTERS:
  ✅ ASCII only: = - | + * #
  ✅ Box drawing: ╔ ═ ╗ ║ ╚ ╝ ╠ ╣ ╦ ╩ ╬
  ❌ NO Unicode emoji or special symbols

COLOR SCHEME (Managed by GandiWinUI):
  Green      : PERFORMANCE / OK Status
  Red        : SECURITY / FAIL Status / Errors
  Yellow     : GAMING / WARN Status
  Cyan       : INFO Status / Headers
  DarkCyan   : Box Frames
  White      : Body text
```

---

## 7. LAUNCHER SPECIFICATION

### 7.1 Launcher.bat Requirements

```batch
@echo off
title GandiWin Launcher
color 0A

:: Detect PowerShell (hybrid method - MANDATORY)
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
:: Continue with %PS% variable
```

### 7.2 Menu Options (FIXED)

```
[1] LAUNCH ALL TERMINALS  → Opens system_check + universal_menu + log_viewer
[2] SYSTEM CHECK          → Opens system_check.ps1 only
[3] UNIVERSAL MENU        → Opens universal_menu.ps1 only
[4] LOG VIEWER            → Opens log_viewer.ps1 only
[5] EXIT                  → Close launcher
```

### 7.3 Terminal Launch Format

```batch
:: CORRECT FORMAT (use %PS% variable):
start "" %PS% -NoExit -ExecutionPolicy Bypass -File "%BASEDIR%system_check.ps1"

:: With inline command:
start "" %PS% -NoExit -ExecutionPolicy Bypass -Command "& { cd '%BASEDIR%'; .\script.ps1 }"
```

### 7.4 Launcher Loop (MUST NOT CLOSE)

```batch
:menu
cls
echo ... menu options ...
set /p CHOICE=  Enter choice:
if "%CHOICE%"=="" goto :menu
if "%CHOICE%"=="1" goto :launch_all
if "%CHOICE%"=="2" goto :launch_system
if "%CHOICE%"=="3" goto :launch_menu
if "%CHOICE%"=="4" goto :launch_logs
if "%CHOICE%"=="5" exit
goto :menu
```

---

## 8. FORBIDDEN PATTERNS (NEVER DO THIS)

### 8.1 Batch Script Sins

```batch
❌ if %errorlevel%==0 (        # Wrong: %errorlevel% expands at parse time
✅ if not errorlevel 1 (       # Correct: runtime evaluation

❌ exit /b                      # Wrong: closes terminal silently
✅ pause & exit /b             # Correct: user acknowledges

❌ goto :eof                   # Wrong: unpredictable behavior
✅ exit /b 0                   # Correct: explicit return

❌ %BASEDIR%script.ps1        # Wrong: missing backslash
✅ %BASEDIR%script.ps1        # Correct: proper path
```

### 8.2 PowerShell Sins

```powershell
❌ goto :label                 # Wrong: PowerShell does not natively support goto
✅ while ($true) { ... }       # Correct: Use proper PowerShell loops

❌ exit                        # Wrong: kills terminal
❌ Close-Host                  # Wrong: kills terminal
❌ Clear-Host without content  # Wrong: blank screen

✅ Write-Host "Exiting..."; pause; exit  # Correct

❌ Invoke-Expression script.ps1  # Wrong: security risk
✅ & .\script.ps1                # Correct: safe invocation

❌ $ErrorActionPreference = "Stop"  # Wrong: global setting
✅ -ErrorAction Stop                # Correct: per-command
```

### 8.3 Path & Encoding Sins

```
⚠️ ENCODING RULES (CRITICAL FOR UI):
✅ UTF-8 WITH BOM: MANDATORY for any script (.ps1/.psm1) containing Box Drawing characters (like ╔, ║). PowerShell 5.1 reads UTF-8 NO-BOM as ANSI, causing severe parsing errors!
✅ UTF-8 WITHOUT BOM: Standard for generic logic scripts without special characters.
❌ ANSI: Avoid unless strictly required for legacy CMD.

❌ Relative paths: .\script.ps1  # Wrong: breaks from different cwd
✅ Absolute paths: %BASEDIR%script.ps1  # Correct

❌ Hardcoded paths: C:\GandiWin  # Wrong: not portable
✅ Dynamic paths: %~dp0 or $PSScriptRoot  # Correct
```

---

## 9. TESTING CHECKLIST (BEFORE COMMIT)

### 9.1 Pre-Commit Tests

```
[ ] launcher.bat opens without errors
[ ] All 4 terminals can be launched
[ ] universal_menu.ps1 displays all 30 features
[ ] Feature selection (1-30) launches correct script
[ ] Terminal stays open after feature execution (-NoExit)
[ ] Logs are written to logs/tweak_activity.log
[ ] No PowerShell parsing errors
[ ] Works on Windows 10 (minimum test)
[ ] Works on Windows 11 (if available)
[ ] All paths resolve correctly
[ ] No hardcoded absolute paths
[ ] File encoding is UTF-8 with BOM if using Box Drawing (UI module)
```

### 9.2 Error Scenarios to Test

```
[ ] Run without Administrator (should work with warnings)
[ ] Run from different directory (paths should still work)
[ ] Input invalid menu option (should show error, not crash)
[ ] Missing feature script (should show "not found", not crash)
[ ] PowerShell not in PATH (launcher should detect and error gracefully)
[ ] logs/ folder doesn't exist (should auto-create)
```

---

## 10. VERSION HISTORY & CHANGELOG

### v3.0 POWER EDITION (Current)

- Full PowerShell-based architecture
- 30 modular features in features/ folder
- Multi-terminal workflow (4 terminals)
- Hacker-style ASCII UI
- Structured logging system
- Windows 10/11 focused

### v2.0 ELITE (Legacy - Deprecated)

- CMD-based architecture
- Limited Windows 7/8 support
- Basic batch scripts
- **DO NOT MIX WITH v3.0**

### v1.0 (Legacy - Deprecated)

- Initial release
- **DO NOT USE**

---

## 11. QUICK REFERENCE

### PowerShell Detection (Copy-Paste Ready)

```batch
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
```

### Terminal Launch (Copy-Paste Ready)

```batch
start "" %PS% -NoExit -ExecutionPolicy Bypass -File "%BASEDIR%script.ps1"
```

### Feature Logging (Copy-Paste Ready)

```batch
echo [%DATE% %TIME%] FEATURE_NAME: Action description >> "%ActivityLog%"
```

### Input Validation (Copy-Paste Ready)

```batch
set /p CHOICE=  Enter choice:
if "%CHOICE%"=="" goto :menu
if "%CHOICE%"=="1" goto :option1
goto :menu
```

---

## 12. CONTACT & SUPPORT

**For AI Assistants:** Follow this document STRICTLY. Do not deviate from specifications. When in doubt, refer to Section 8 (Forbidden Patterns).

**For Human Developers:** This document is the single source of truth. Any feature not documented here should follow the same patterns and conventions.

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-22  
**Applies To:** GandiWin v3.0 POWER EDITION  
**Status:** PRODUCTION READY

---

## 🚨 FINAL WARNING

**VIOLATING THESE RULES WILL CAUSE:**

- Terminal closing unexpectedly
- PowerShell parsing errors
- Path resolution failures
- Logging failures
- User confusion and frustration

**FOLLOW THIS DOCUMENT. ALWAYS.**
