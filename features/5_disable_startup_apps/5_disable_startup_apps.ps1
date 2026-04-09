# encoding: UTF-8
# GandiWin :: 05 Disable Startup Apps
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) { Write-Host "[ERROR] PS 5.1+ required!" -ForegroundColor Red; pause; exit 1 }

if ($PSScriptRoot -ne '') { $ScriptDir = $PSScriptRoot }
else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

$UIModule = "$ScriptDir\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

$LogFile = "$ScriptDir\..\..\logs\menu.log"
if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }

function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [05_STARTUP] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

$SafeKeywords = @("antivirus", "defender", "firewall", "audio", "realtek", "nvidia", "amd", "intel", "driver", "bluetooth", "wacom", "logitech", "steelseries", "razer", "asus", "msi")

function Get-StartupList {
    $result = @()
    $regPaths = @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; Scope = "HKCU" }
        @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"; Scope = "HKLM" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"; Scope = "HKCU-Once" }
        @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"; Scope = "HKLM-Once" }
    )
    foreach ($rp in $regPaths) {
        if (Test-Path $rp.Path) {
            try {
                $props = Get-ItemProperty -Path $rp.Path -ErrorAction Stop
                $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                    $isEssential = $false
                    foreach ($kw in $SafeKeywords) {
                        if ($_.Name -match $kw -or $_.Value -match $kw) { $isEssential = $true; break }
                    }
                    $result += [PSCustomObject]@{
                        Name    = $_.Name.Substring(0, [Math]::Min($_.Name.Length, 30))
                        Rec     = if ($isEssential) { "unsafe" } else { "safe" }
                        Type    = "REG"
                        RegPath = $rp.Path
                        RegName = $_.Name
                        Checked = -not $isEssential
                    }
                }
            }
            catch {}
        }
    }

    # Startup folders
    $startupFolders = @(
        [Environment]::GetFolderPath("Startup")
        [Environment]::GetFolderPath("CommonStartup")
    )
    foreach ($folder in $startupFolders) {
        if (Test-Path $folder) {
            Get-ChildItem -Path $folder -Filter "*.lnk" -ErrorAction SilentlyContinue | ForEach-Object {
                $isEssential = $false
                foreach ($kw in $SafeKeywords) {
                    if ($_.Name -match $kw) { $isEssential = $true; break }
                }
                $result += [PSCustomObject]@{
                    Name    = $_.BaseName.Substring(0, [Math]::Min($_.BaseName.Length, 30))
                    Rec     = if ($isEssential) { "unsafe" } else { "optional" }
                    Type    = "FOLDER"
                    RegPath = $_.FullName
                    RegName = $_.Name
                    Checked = -not $isEssential
                }
            }
        }
    }

    if ($result.Count -eq 0) {
        Write-Host "  [i] Tidak ada startup entry yang terdeteksi." -ForegroundColor DarkGray
    }
    return $result
}

function Invoke-DisableStartup {
    param($Item)
    try {
        if ($Item.Type -eq "REG") {
            Remove-ItemProperty -Path $Item.RegPath -Name $Item.RegName -ErrorAction Stop
            Write-ActivityLog "REMOVED REG STARTUP: $($Item.RegName)" "OK"
            return $true
        }
        elseif ($Item.Type -eq "FOLDER") {
            if (Test-Path -LiteralPath $Item.RegPath) {
                Remove-Item -LiteralPath $Item.RegPath -Force -ErrorAction Stop
                Write-ActivityLog "REMOVED FOLDER STARTUP: $($Item.RegName)" "OK"
            }
            return $true
        }
        return $false
    }
    catch {
        Write-ActivityLog "FAILED: $($_.Exception.Message)" "FAIL"
        Write-Host "  [!] Melewati $($Item.Name) (Tidak didukung di sistem ini)..." -ForegroundColor Yellow
        return $false
    }
}

function Invoke-ChecklistUI {
    param([string]$Title, [array]$Items)
    if ($Items.Count -eq 0) { Write-GandiStatus -Status "OK" -Message "Tidak ada startup entry."; Start-Sleep 2; return }
    $Checked = @{}
    for ($i = 0; $i -lt $Items.Count; $i++) { $Checked[$i] = $Items[$i].Checked }
    $Cursor = 0; $Vis = 24; $Half = 12; $Top = 0
    [Console]::Clear()
    while ($true) {
        if ($Cursor -lt $Top) { $Top = $Cursor }
        if ($Cursor -ge ($Top + $Vis)) { $Top = $Cursor - $Vis + 1 }
        [Console]::SetCursorPosition(0, 0)
        Show-GandiHeader -Title $Title
        $sel = ($Checked.Values | Where-Object { $_ }).Count
        Show-GandiKeyValue -Key "Total" -Value $Items.Count -ValueColor "White"
        Show-GandiKeyValue -Key "Pilih" -Value $sel -ValueColor "Red"
        Write-Host "  WHITE=safe | YELLOW=optional | RED=essential (jangan dipilih)" -ForegroundColor DarkGray
        Write-Host ""
        for ($i = 0; $i -lt $Half; $i++) {
            $absL = $Top + $i
            if ($absL -lt $Items.Count) {
                $li = $Items[$absL]
                $lc = if ($Checked[$absL]) { "[X]" } else { "[ ]" }
                $ln = if ($li.Name.Length -gt 30) { $li.Name.Substring(0, 27) + ".." } else { $li.Name }
                $lf = switch ($li.Rec) { 'safe' { 'White' } 'unsafe' { 'Red' } default { 'Yellow' } }
                $lb = if ($absL -eq $Cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}  " -f $lc, $ln) -ForegroundColor $lf -BackgroundColor $lb -NoNewline
            }
            $absR = $Top + $i + $Half
            if ($absR -lt $Items.Count) {
                $ri = $Items[$absR]
                $rc = if ($Checked[$absR]) { "[X]" } else { "[ ]" }
                $rn = if ($ri.Name.Length -gt 30) { $ri.Name.Substring(0, 27) + ".." } else { $ri.Name }
                $rf = switch ($ri.Rec) { 'safe' { 'White' } 'unsafe' { 'Red' } default { 'Yellow' } }
                $rb = if ($absR -eq $Cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}" -f $rc, $rn) -ForegroundColor $rf -BackgroundColor $rb
            }
            else { Write-Host "".PadRight(40) }
        }
        Write-Host "`n  NAV: ARROWS | TOGGLE: SPACE | ALL: A | RESET: N | EXEC: ENTER | ESC: BACK" -ForegroundColor DarkGray
        $k = [Console]::ReadKey($true)
        switch ($k.Key) {
            'UpArrow' { if ($Cursor -gt 0) { $Cursor-- } }
            'DownArrow' { if ($Cursor -lt ($Items.Count - 1)) { $Cursor++ } }
            'LeftArrow' { if ($Cursor -ge $Half) { $Cursor -= $Half } }
            'RightArrow' { if ($Cursor + $Half -lt $Items.Count) { $Cursor += $Half } }
            'Spacebar' { $Checked[$Cursor] = -not $Checked[$Cursor] }
            'A' { 0..($Items.Count - 1) | ForEach-Object { $Checked[$_] = $true } }
            'N' { 0..($Items.Count - 1) | ForEach-Object { $Checked[$_] = $false } }
            'Escape' { return }
            'Enter' {
                $exec = 0..($Items.Count - 1) | Where-Object { $Checked[$_] } | ForEach-Object { $Items[$_] }
                if ($exec.Count -eq 0) { continue }
                [Console]::Clear(); Show-GandiHeader -Title "KONFIRMASI"
                Write-Host "  Disable $($exec.Count) startup entry? TIDAK BISA DIBATALKAN. (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-DisableStartup -Item $item | Out-Null
                }
                Write-GandiStatus -Status "OK" -Message "Selesai."; Start-Sleep 2; return
            }
        }
    }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 05 DISABLE STARTUP APPS"
    Show-GandiHeader -Title "05 DISABLE STARTUP APPS"
    Write-Host ""
    Write-Host "  [1] Scan dan Pilih Startup Entry untuk Dinonaktifkan" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') {
        Write-GandiStatus -Status "WAIT" -Message "Memindai startup entries..."
        Write-ActivityLog "TWEAK INITIATED: #5 - Disable Startup Apps"
        $list = Get-StartupList
        Invoke-ChecklistUI "05 DISABLE STARTUP APPS" $list
    }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
