# GANDIWIN v3.0 — ATURAN KERAS PENGEMBANGAN

> Dokumen ini adalah **SINGLE SOURCE OF TRUTH**. Semua AI & developer WAJIB mengikutinya. Pelanggaran = failure.

---

## 1. TARGET OS & MINIMUM REQUIREMENT

| OS                        | Arch      | Status          | Priority |
| ------------------------- | --------- | --------------- | -------- |
| Windows 10 (Build 19041+) | 32/64-bit | ✅ FULL SUPPORT | P0       |
| Windows 11                | 64-bit    | ✅ FULL SUPPORT | P0       |
| Windows 7 (WMF 5.1)       | 32/64-bit | ⚠️ LIMITED      | P3       |
| Windows 8/8.1             | any       | ❌ SKIP         | —        |

**Hard requirement:** PowerShell 5.1 (powershell.exe Desktop Edition, BUKAN pwsh.exe/PS Core).

---

## 2. LANGUAGE STACK

```
PRIMARY:    PowerShell 5.1 (.ps1)
BOOTSTRAP:  Batch script (.bat) untuk launcher
FORBIDDEN:  VBScript, JS, C#, .NET assemblies, pwsh.exe (PS Core)
```

---

## 3. POWERSHELL 5.1 STRICT MODE (WAJIB)

### 3.1 Sintaks yang DILARANG (Blacklist)

```powershell
❌ Ternary operator      : $x ? 'a' : 'b'          # PS 7+ only
❌ Pipeline chain        : cmd1 && cmd2             # PS 7+ only
❌ Null-coalescing       : $x ?? 'default'          # PS 7+ only
❌ ForEach-Object -Parallel                         # PS 7+ only
❌ goto :label                                      # tidak ada di PowerShell
❌ Invoke-Expression script.ps1                     # security risk
❌ $ErrorActionPreference = "Stop"                  # global setting berbahaya
❌ if ($_ -strip)                                   # -strip bukan operator valid
❌ switch { 'val' { continue } }                    # continue di switch target switch, bukan while
❌ function Log-Activity { }                        # 'Log' bukan approved PS verb
❌ exit / Close-Host                                # membunuh terminal
```

### 3.2 Sintaks yang BENAR

```powershell
✅ if ($x) { 'a' } else { 'b' }                   # gunakan if/else tradisional
✅ while ($true) { ... }                            # loop yang proper
✅ & .\script.ps1                                   # safe invocation
✅ -ErrorAction Stop                                # per-command, bukan global
✅ if ($_ -ne '') { ... }                           # explicit string check
✅ function Write-ActivityLog { ... }               # 'Write' adalah approved verb
✅ if ($DoRescan) { continue }                      # flag variable + continue di while
✅ Write-Host "Exiting..."; Start-Sleep 1; exit    # proper exit sequence
```

### 3.3 Batasan .NET

Gunakan **hanya** .NET Framework 4.5.2–4.8. Dilarang namespace .NET Core.
Untuk Windows API level rendah (user32.dll, kernel32.dll), gunakan `Add-Type` dengan sintaks C# (P/Invoke) — jangan suruh user download .exe/.dll tambahan.

### 3.4 Kompatibilitas WMI & Registry

```powershell
# Cek OS sebelum pakai fitur spesifik OS
$OSBuild = [System.Environment]::OSVersion.Version.Build
if ($OSBuild -ge 22000) {
    # Windows 11
} elseif ($OSBuild -ge 19041) {
    # Windows 10
} else {
    # Windows 7 fallback
}

# Cek PS version di setiap script utama (WAJIB)
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    pause; exit 1
}
```

---

## 4. ARSITEKTUR TERMINAL (4 TERMINALS)

```
Terminal 1: system_check.ps1    → Hardware/OS overview    (Color: Green)
Terminal 2: universal_menu.ps1  → Menu 12 fitur + 1 preset (Color: Cyan)
Terminal 3: log_viewer.ps1      → Daemon log monitor       (Color: Yellow)
Terminal 4: Feature execution   → Per-fitur, dinamis       (Color: per kategori)
```

---

## 5. STRUKTUR FOLDER (HARD STRUCTURE)

```
GandiWin/
├── launcher.bat              # MUST
├── system_check.ps1          # MUST
├── universal_menu.ps1        # MUST
├── log_viewer.ps1            # MUST
├── features/                 # MUST: 12 folder fitur + 1 preset
│   ├── 1_remove_bloatware/
│   │   └── 1_remove_bloatware.ps1   # ← ekstensi WAJIB .ps1
│   └── ... (format: {num}_{slug}/)
├── modules/ (file file penting dan berguna untuk keseluruhan program)
│   └── GandiWinUI.psm1       # MUST
└── logs/
    └── menu.log              # Central daemon log
```

**Naming convention folder fitur:**

- Format: `{number}_{slug_lowercase_underscore}/`
- Script WAJIB sama nama dengan folder, ekstensi `.ps1`
- Nomor 1–13, tanpa leading zero di nama folder

---

## 6. 12 FITUR + 1 PRESET

| #   | Feature Name           | Slug                       | Category    | Menyerap Lama  |
| --- | ---------------------- | -------------------------- | ----------- | -------------- |
| 01  | Remove Bloatware       | `1_remove_bloatware`       | CLEANUP     | 03, 26, 27, 30 |
| 02  | Disable BG Services    | `2_disable_bg_services`    | PERFORMANCE | 05, 08, 14, 24 |
| 03  | Disable BG Apps        | `3_disable_bg_apps`        | PERFORMANCE | 06, 19, 21     |
| 04  | Disable Task Scheduler | `4_disable_task_scheduler` | PRIVACY     | 09             |
| 05  | Disable Startup Apps   | `5_disable_startup_apps`   | PERFORMANCE | 04             |
| 06  | Portable Antivirus     | `6_portable_antivirus`     | SECURITY    | 02             |
| 07  | Everything Search      | `7_everything_search`      | UI          | 28             |
| 08  | Apply Visual Effects   | `8_apply_visual_effects`   | GAMING/UI   | 18, 20, 22, 25 |
| 09  | Apply Quick CPU        | `9_apply_quick_cpu`        | PERFORMANCE | 15, 16, 17, 23 |
| 10  | Telemetry              | `10_telemetry`             | PRIVACY     | 07, 29         |
| 11  | Disk                   | `11_disk`                  | MAINTENANCE | 10, 11, 12, 13 |
| 12  | Memory Management      | `12_memory_management`     | PERFORMANCE | 01, 15         |
| 13  | Apply Custom Presets   | `13_apply_custom_presets`  | MASTER      | 1-12           |

---

## 7. ARSITEKTUR WAJIB SETIAP FITUR (5 LAPIS)

Setiap script `.ps1` di folder `features/` HARUS mengikuti 5 lapis ini:

### Layer 1 — Initialization

```powershell
# PS version check
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) { Write-Host "[ERROR] PS 5.1+ required!" -ForegroundColor Red; pause; exit 1 }

# Resolve script dir (robust, works via Start-Process)
if ($PSScriptRoot -ne '') { $ScriptDir = $PSScriptRoot }
else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

# Import UI module
$UIModule = "$ScriptDir\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

# Init log
$LogFile = "$ScriptDir\..\..\logs\menu.log"
if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }
```

### Layer 2 — Data Loader

```powershell
function Get-<NamaData>List {
    # Kembalikan array of PSCustomObject
    # Properti WAJIB: Name (String, maks 30 char), Checked (Boolean), Rec ('safe'|'unsafe'|'optional')
    # Properti tambahan sesuai kebutuhan eksekusi
    $result = @()
    # ... logic ...
    return $result
}
```

### Layer 3 — Execution Logic

```powershell
function Invoke-<NamaAction> {
    param($Item)
    # Gunakan try...catch secara diam-diam
    # return $true jika sukses, $false jika gagal
    try {
        # operasi sistem
        return $true
    } catch {
        # LOG ke file, jangan tampilkan merah ke konsol
        Write-ActivityLog "FAILED: $($_.Exception.Message)" "FAIL"
        Write-Host "  [!] Melewati $($Item.Name) (Tidak didukung di sistem ini)..." -ForegroundColor Yellow
        return $false
    }
}
```

### Layer 4 — Interactive UI (DILARANG DIUBAH)

Template TUI 2-kolom anti-flicker. Gunakan persis seperti ini:

```powershell
function Invoke-ChecklistUI {
    param([string]$Title, [array]$Items, [switch]$Deep)
    if ($Items.Count -eq 0) { Write-GandiStatus -Status "OK" -Message "Kosong."; Start-Sleep 1; return }

    $Checked = @{}; for ($i = 0; $i -lt $Items.Count; $i++) { $Checked[$i] = $Items[$i].Checked }
    $Cursor = 0; $Vis = 24; $Half = 12; $Top = 0
    [Console]::Clear()

    while ($true) {
        if ($Cursor -lt $Top) { $Top = $Cursor }
        if ($Cursor -ge ($Top + $Vis)) { $Top = $Cursor - $Vis + 1 }

        [Console]::SetCursorPosition(0, 0)  # WAJIB UNTUK ANTI-FLICKER
        Show-GandiHeader -Title $Title
        $sel = ($Checked.Values | Where-Object { $_ }).Count
        Show-GandiKeyValue -Key "Total" -Value $Items.Count -ValueColor "White"
        Show-GandiKeyValue -Key "Pilih" -Value $sel -ValueColor "Red"
        Write-Host ""

        for ($i = 0; $i -lt $Half; $i++) {
            $LIdx = $i; $RIdx = $i + $Half
            $absL = $Top + $LIdx
            if ($absL -lt $Items.Count) {
                $li = $Items[$absL]
                $lc = if ($Checked[$absL]) { "[X]" } else { "[ ]" }
                $ln = if ($li.Name.Length -gt 30) { $li.Name.Substring(0, 27) + ".." } else { $li.Name }
                $lf = switch ($li.Rec) { 'safe' { 'White' } 'unsafe' { 'Red' } default { 'Yellow' } }
                $lb = if ($absL -eq $Cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}  " -f $lc, $ln) -ForegroundColor $lf -BackgroundColor $lb -NoNewline
            }
            $absR = $Top + $RIdx
            if ($absR -lt $Items.Count) {
                $ri = $Items[$absR]
                $rc = if ($Checked[$absR]) { "[X]" } else { "[ ]" }
                $rn = if ($ri.Name.Length -gt 30) { $ri.Name.Substring(0, 27) + ".." } else { $ri.Name }
                $rf = switch ($ri.Rec) { 'safe' { 'White' } 'unsafe' { 'Red' } default { 'Yellow' } }
                $rb = if ($absR -eq $Cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}" -f $rc, $rn) -ForegroundColor $rf -BackgroundColor $rb
            }
            else { Write-Host "".PadRight(40) }  # timpa sisa frame sebelumnya
        }

        Write-Host "`n  NAV: ARROWS | TOGGLE: SPACE | RESET: N | ALL: A | EXEC: ENTER | ESC: BACK" -ForegroundColor DarkGray
        $k = [Console]::ReadKey($true)
        switch ($k.Key) {
            'UpArrow'   { if ($Cursor -gt 0) { $Cursor-- } }
            'DownArrow' { if ($Cursor -lt ($Items.Count - 1)) { $Cursor++ } }
            'LeftArrow' { if ($Cursor -ge $Half) { $Cursor -= $Half } }
            'RightArrow'{ if ($Cursor + $Half -lt $Items.Count) { $Cursor += $Half } }
            'Spacebar'  { $Checked[$Cursor] = -not $Checked[$Cursor] }
            'A'         { 0..($Items.Count - 1) | ForEach-Object { $Checked[$_] = $true } }
            'N'         { 0..($Items.Count - 1) | ForEach-Object { $Checked[$_] = $false } }
            'Escape'    { return }
            'Enter' {
                $exec = 0..($Items.Count - 1) | Where-Object { $Checked[$_] } | ForEach-Object { $Items[$_] }
                if ($exec.Count -eq 0) { continue }
                [Console]::Clear(); Show-GandiHeader -Title "KONFIRMASI"
                Write-Host "  Eksekusi $($exec.Count) item? (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-<NamaAction> -Item $item -DeepClean $Deep | Out-Null  # sesuaikan nama fungsi; teruskan $Deep jika fungsi membutuhkannya
                }
                Write-GandiStatus -Status "OK" -Message "Selesai."; Start-Sleep 2; return
            }
        }
    }
}
```

### Layer 5 — Main Loop

```powershell
while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: NAMA FITUR"
    Show-GandiHeader -Title "NN NAMA FITUR"
    Write-Host ""
    Write-Host "  [1] Pilihan 1" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') { Invoke-ChecklistUI "JUDUL" (Get-<NamaData>List) }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
```

---

## 8. LOGGING (WAJIB)

```powershell
# SATU fungsi logging per script, letakkan di Layer 1
function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [NN_SLUG] $Message" -ErrorAction SilentlyContinue } catch {}
}

# Log WAJIB di setiap titik kritis:
Write-ActivityLog "Module launched"
Write-ActivityLog "TWEAK INITIATED: #N - Nama Fitur"
Write-ActivityLog "COMPLETED: Nama aksi" "OK"
Write-ActivityLog "FAILED: $($_.Exception.Message)" "FAIL"
```

**Target log:** `$ScriptDir\..\..\logs\menu.log` (central daemon log untuk log_viewer.ps1)

---

## 9. DEFENSIVE ERROR HANDLING (WAJIB DI SEMUA OPERASI SISTEM)

```powershell
try {
    # Setiap operasi Registry, WMI, Service, FileSystem WAJIB pakai -ErrorAction Stop
    Get-ItemProperty -Path "HKLM:\..." -ErrorAction Stop
} catch {
    # DILARANG: Write-Error atau teks merah yang membuat panik pelanggan
    # WAJIB: simpan ke log, tampilkan kuning, lanjutkan dengan continue
    Write-ActivityLog "FAILED: $($_.Exception.Message)" "FAIL"
    Write-Host "  [!] Melewati proses X (Tidak didukung di sistem ini)..." -ForegroundColor Yellow
    continue
}
```

---

## 10. UI MODULE — GandiWinUI.psm1

Seluruh styling terminal WAJIB pakai module ini. Dilarang custom `Write-Host` spaghetti.

| Fungsi                                                                  | Kegunaan                                                  |
| ----------------------------------------------------------------------- | --------------------------------------------------------- |
| `Set-GandiConsole -Title "..."`                                         | Setup terminal (font Consolas 18, title, clear)           |
| `Show-GandiBanner`                                                      | Banner utama GandiWin (untuk Control Center & Log Viewer) |
| `Show-GandiHeader -Title "..."`                                         | Header per-fitur                                          |
| `Show-GandiBox -Title "..."`                                            | Box section dengan border                                 |
| `Show-GandiKeyValue -Key "" -Value ""`                                  | Baris key: value                                          |
| `Write-GandiStatus -Status "OK\|FAIL\|WARN\|INFO\|WAIT" -Message "..."` | Status line berwarna                                      |
| `Invoke-GandiTypewriter -Text "..." -Color "..."`                       | Teks animasi typewriter                                   |

**Karakter yang diizinkan:** ASCII (`= - | + * #`) + Box drawing (`╔ ═ ╗ ║ ╚ ╝ ╠ ╣ ╦ ╩ ╬`)
**Dilarang:** Unicode emoji, simbol non-ASCII lainnya

**Encoding:** UTF-8 WITH BOM untuk file yang mengandung karakter box drawing.

---

## 11. LAUNCHER (launcher.bat)

```batch
@echo off
setlocal enabledelayedexpansion
title GandiWin Launcher
color 0A
set "BASEDIR=%~dp0"

where powershell >nul 2>&1
if not errorlevel 1 ( set "PS=powershell" & goto :ps_found )
where pwsh >nul 2>&1
if not errorlevel 1 ( set "PS=pwsh" & goto :ps_found )
if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" & goto :ps_found )
echo [ERROR] No PowerShell found! & pause & exit /b 1

:ps_found
:menu
cls
:: ... tampilkan menu ...
set /p CHOICE=  Enter choice:
if "%CHOICE%"=="" goto :menu
if "%CHOICE%"=="1" goto :launch_all
if "%CHOICE%"=="5" exit
goto :menu
```

**Format launch terminal (STRICT):**

```batch
start "" %PS% -NoExit -ExecutionPolicy Bypass -File "%BASEDIR%script.ps1"
```

---

## 12. TERMINAL BEHAVIOR (NON-NEGOTIABLE)

```
✅ SELALU: -NoExit (terminal tetap terbuka)
✅ SELALU: -ExecutionPolicy Bypass
✅ SELALU: pause atau animasi sebelum exit agar user acknowledge
❌ JANGAN: exit tanpa informasi (user tidak lihat hasil)
❌ JANGAN: Close-Host (membunuh terminal)
❌ JANGAN: Relative paths (gunakan $PSScriptRoot atau %~dp0)
❌ JANGAN: Hardcoded absolute path (C:\GandiWin)
```

---

## 13. TRANSLASI DARI REPO GITHUB (REVERSE ENGINEER GUIDE)

Saat menerjemahkan tool GUI/C#/C++/Batch dari GitHub ke PowerShell CLI:

1. **Abaikan semua kode UI/Form** — fokus ke inti perubahan sistem
2. **Ekstrak:** key registry yang diubah, service yang dimatikan, task yang dihapus
3. **Bungkus dalam fungsi PowerShell** dengan try...catch (Layer 3)
4. **Cek OS compatibility** sebelum operasi spesifik OS
5. **Jangan suruh user download file tambahan** — embed P/Invoke jika perlu DLL call

---

## 14. CHECKLIST SEBELUM COMMIT

```
[ ] PS version check ada di setiap script utama
[ ] Import GandiWinUI.psm1 ada
[ ] Logging ke menu.log ada (Write-ActivityLog)
[ ] Semua operasi sistem dibungkus try...catch -ErrorAction Stop
[ ] Tidak ada sintaks PS 7+ (ternary, ??, &&)
[ ] Tidak ada fungsi dengan verb non-approved (Log-, Fetch-, dll)
[ ] Tidak ada hardcoded path
[ ] Terminal tidak langsung close (ada -NoExit / pause / sleep)
[ ] Encoding UTF-8 BOM jika ada box drawing characters
[ ] File naming: {num}_{slug}.ps1 sesuai tabel fitur
[ ] Semua nama fungsi WAJIB menggunakan Approved Verbs PS (Get-, Set-, Invoke-, Write-, Remove-, Clear-, Test-, dll). Dilarang: Log-, Fetch-, Check-, dll.
```

---

**Document Version:** 3.0 | **Last Updated:** 2026-03-24 | **Applies To:** GandiWin v3.0 POWER EDITION — 12 METODE EDITION
