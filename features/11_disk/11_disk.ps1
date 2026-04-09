# encoding: UTF-8
# GandiWin :: 11 Disk
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
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [11_DISK] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

function Get-DiskTweakList {
    return @(
        [PSCustomObject]@{ Name = "Disk Cleanup (cleanmgr)"; Rec = "safe"; Type = "CMD"; Id = "CLEANMGR"; Checked = $true }
        [PSCustomObject]@{ Name = "Temp Files Delete"; Rec = "safe"; Type = "FS"; Id = "TEMP_CLEAN"; Checked = $true }
        [PSCustomObject]@{ Name = "Prefetch Clean"; Rec = "optional"; Type = "FS"; Id = "PREFETCH_CLEAN"; Checked = $false }
        [PSCustomObject]@{ Name = "AppData Temp Clean"; Rec = "safe"; Type = "FS"; Id = "APPDATA_TEMP"; Checked = $true }
        [PSCustomObject]@{ Name = "Windows Error Reports Clean"; Rec = "safe"; Type = "FS"; Id = "WER_CLEAN"; Checked = $true }
        [PSCustomObject]@{ Name = "Chkdsk Schedule (C:)"; Rec = "optional"; Type = "CMD"; Id = "CHKDSK_SCHED"; Checked = $false }
        [PSCustomObject]@{ Name = "Optimize C: (TRIM/Defrag)"; Rec = "safe"; Type = "CMD"; Id = "OPTIMIZE_C"; Checked = $true }
        [PSCustomObject]@{ Name = "Ghost Drivers Detect"; Rec = "optional"; Type = "CMD"; Id = "GHOST_DRV"; Checked = $false }
        [PSCustomObject]@{ Name = "System File Check (sfc)"; Rec = "optional"; Type = "CMD"; Id = "SFC_SCAN"; Checked = $false }
        [PSCustomObject]@{ Name = "DISM CheckHealth"; Rec = "optional"; Type = "CMD"; Id = "DISM_CHECK"; Checked = $false }
    )
}

function Invoke-DiskTweak {
    param($Item)
    try {
        switch ($Item.Id) {
            "CLEANMGR" {
                & cleanmgr /sageset:1 2>&1 | Out-Null
                & cleanmgr /sagerun:1 2>&1 | Out-Null
                Write-ActivityLog "CLEANMGR COMPLETED" "OK"
            }
            "TEMP_CLEAN" {
                $tempPaths = @($env:TEMP, $env:TMP, "C:\Windows\Temp")
                foreach ($p in $tempPaths) {
                    if (Test-Path $p) {
                        Get-ChildItem $p -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
                Write-ActivityLog "TEMP CLEANED" "OK"
            }
            "PREFETCH_CLEAN" {
                $pf = "C:\Windows\Prefetch"
                if (Test-Path $pf) {
                    Get-ChildItem $pf -Filter "*.pf" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                }
                Write-ActivityLog "PREFETCH CLEANED" "OK"
            }
            "APPDATA_TEMP" {
                $localTemp = Join-Path $env:LOCALAPPDATA "Temp"
                if (Test-Path $localTemp) {
                    Get-ChildItem $localTemp -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
                Write-ActivityLog "APPDATA TEMP CLEANED" "OK"
            }
            "WER_CLEAN" {
                $werDirs = @(
                    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\WER\ReportQueue")
                    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\WER\ReportArchive")
                    "C:\ProgramData\Microsoft\Windows\WER\ReportQueue"
                    "C:\ProgramData\Microsoft\Windows\WER\ReportArchive"
                )
                foreach ($d in $werDirs) {
                    if (Test-Path $d) { Get-ChildItem $d -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
                }
                Write-ActivityLog "WER REPORTS CLEANED" "OK"
            }
            "CHKDSK_SCHED" {
                $result = & chkntfs /d 2>&1
                & chkntfs /x C: 2>&1 | Out-Null
                & chkntfs /c C: 2>&1 | Out-Null
                Write-ActivityLog "CHKDSK SCHEDULED ON NEXT BOOT" "OK"
                Write-Host "  [i] Chkdsk akan berjalan saat restart berikutnya." -ForegroundColor Yellow
            }
            "OPTIMIZE_C" {
                Write-GandiStatus -Status "WAIT" -Message "Menjalankan Optimize-Volume C:..."
                $vol = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
                if ($vol) {
                    Optimize-Volume -DriveLetter C -ReTrim -Verbose -ErrorAction SilentlyContinue
                    Write-ActivityLog "OPTIMIZE-VOLUME C: DONE" "OK"
                }
                else {
                    & defrag C: /U /V 2>&1 | Out-Null
                    Write-ActivityLog "DEFRAG C: DONE (FALLBACK)" "OK"
                }
            }
            "GHOST_DRV" {
                $env:devmgr_show_nonpresent_devices = "1"
                $hiddenDevs = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Unknown" -or $_.Present -eq $false }
                if ($hiddenDevs.Count -gt 0) {
                    [Console]::Clear()
                    Show-GandiHeader -Title "GHOST DRIVERS TERDETEKSI"
                    Write-Host "  Ghost devices ditemukan:" -ForegroundColor Yellow
                    $hiddenDevs | Select-Object -First 20 | ForEach-Object {
                        Write-Host ("  - {0,-40} [{1}]" -f $_.FriendlyName, $_.InstanceId.Substring(0, [Math]::Min($_.InstanceId.Length, 30))) -ForegroundColor White
                    }
                    Write-Host ""
                    Write-Host "  Hapus semua ghost drivers? (YES/NO)" -ForegroundColor Red
                    if ((Read-Host "  CMD") -eq 'YES') {
                        foreach ($d in $hiddenDevs) { & pnputil /remove-device $d.InstanceId 2>&1 | Out-Null }
                        Write-ActivityLog "GHOST DRIVERS REMOVED: $($hiddenDevs.Count)" "OK"
                    }
                }
                else {
                    Write-Host "  [i] Tidak ada ghost driver ditemukan." -ForegroundColor Cyan
                    Write-ActivityLog "NO GHOST DRIVERS" "OK"
                }
                Start-Sleep 2
            }
            "SFC_SCAN" {
                Write-GandiStatus -Status "WAIT" -Message "Menjalankan sfc /scannow (bisa 5-15 menit)..."
                & sfc /scannow 2>&1 | Out-Null
                Write-ActivityLog "SFC SCANNOW COMPLETED" "OK"
            }
            "DISM_CHECK" {
                Write-GandiStatus -Status "WAIT" -Message "Menjalankan DISM CheckHealth..."
                & DISM /Online /Cleanup-Image /CheckHealth 2>&1 | Out-Null
                Write-ActivityLog "DISM CHECKHEALTH COMPLETED" "OK"
            }
        }
        return $true
    }
    catch {
        Write-ActivityLog "FAILED: $($_.Exception.Message)" "FAIL"
        Write-Host "  [!] Melewati $($Item.Name) (Tidak didukung di sistem ini)..." -ForegroundColor Yellow
        return $false
    }
}

function Invoke-ChecklistUI {
    param([string]$Title, [array]$Items)
    if ($Items.Count -eq 0) { Write-GandiStatus -Status "OK" -Message "Kosong."; Start-Sleep 1; return }
    $Checked = @{}
    for ($i = 0; $i -lt $Items.Count; $i++) { $Checked[$i] = $Items[$i].Checked }
    $Cursor = 0; $Half = 6; $Top = 0
    [Console]::Clear()
    while ($true) {
        [Console]::SetCursorPosition(0, 0)
        Show-GandiHeader -Title $Title
        $sel = ($Checked.Values | Where-Object { $_ }).Count
        Show-GandiKeyValue -Key "Total" -Value $Items.Count -ValueColor "White"
        Show-GandiKeyValue -Key "Pilih" -Value $sel -ValueColor "Red"
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
                Write-Host "  Jalankan $($exec.Count) disk operation? (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-DiskTweak -Item $item | Out-Null
                }
                Write-GandiStatus -Status "OK" -Message "Selesai."; Start-Sleep 2; return
            }
        }
    }
}

function Show-DiskInfo {
    [Console]::Clear()
    Show-GandiHeader -Title "11 DISK INFO"
    Write-Host ""
    try {
        $disks = Get-WmiObject -Class Win32_DiskDrive -ErrorAction Stop
        foreach ($d in $disks) {
            $sizeGB = [Math]::Round($d.Size / 1GB, 1)
            Show-GandiKeyValue -Key $d.Caption -Value "$sizeGB GB | $($d.InterfaceType)" -ValueColor "Cyan"
        }
        Write-Host ""
        $vols = Get-Volume -ErrorAction Stop | Where-Object { $_.DriveLetter -ne $null }
        foreach ($v in $vols) {
            $freeGB = [Math]::Round($v.SizeRemaining / 1GB, 1)
            $totalGB = [Math]::Round($v.Size / 1GB, 1)
            $pct = if ($v.Size -gt 0) { [Math]::Round(($v.SizeRemaining / $v.Size) * 100) } else { 0 }
            Show-GandiKeyValue -Key "$($v.DriveLetter): $($v.FileSystemLabel)" -Value "${freeGB}GB free / ${totalGB}GB (${pct}%)" -ValueColor $(if ($pct -lt 15) { "Red" } elseif ($pct -lt 30) { "Yellow" } else { "Green" })
        }
    }
    catch {
        Write-Host "  [!] Error membaca info disk: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  Tekan tombol apapun untuk kembali..." -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 11 DISK"
    Show-GandiHeader -Title "11 DISK"
    Write-Host ""
    Write-Host "  [1] Disk Info" -ForegroundColor Cyan
    Write-Host "  [2] Pilih dan Jalankan Disk Operations" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') { Show-DiskInfo }
    elseif ($c -eq '2') {
        Write-ActivityLog "TWEAK INITIATED: #11 - Disk"
        Invoke-ChecklistUI "11 DISK" (Get-DiskTweakList)
    }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
