# encoding: UTF-8
# GandiWin :: 12 Memory Management
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
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [12_MEMORY] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

function Show-SystemHealth {
    [Console]::Clear()
    Show-GandiHeader -Title "12 MEMORY MANAGEMENT - HEALTH CHECK"
    Write-Host ""

    # RAM info
    Show-GandiBox -Title "RAM STATUS"
    try {
        $cs = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
        $ramMB = [Math]::Round($cs.TotalPhysicalMemory / 1MB)
        $ramGB = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
        Show-GandiKeyValue -Key "Total RAM" -Value "$ramGB GB ($ramMB MB)" -ValueColor "Cyan"

        $slots = Get-WmiObject -Class Win32_PhysicalMemory -ErrorAction SilentlyContinue
        if ($slots) {
            $slotNum = 0
            foreach ($s in $slots) {
                $slotNum++
                $slotGB = [Math]::Round($s.Capacity / 1GB, 1)
                $speed = $s.Speed
                $type = switch ($s.SMBIOSMemoryType) { 26 { "DDR4" } 34 { "DDR5" } 24 { "DDR3" } 21 { "DDR2" } default { "DDR" } }
                Show-GandiKeyValue -Key "Slot $slotNum" -Value "${slotGB}GB $type @ ${speed}MHz" -ValueColor "White"
            }
        }
        # Available RAM
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
        $availMB = [Math]::Round($os.FreePhysicalMemory / 1KB)
        $usedMB = $ramMB - $availMB
        $pct = [Math]::Round(($usedMB / $ramMB) * 100)
        $color = if ($pct -gt 85) { "Red" } elseif ($pct -gt 65) { "Yellow" } else { "Green" }
        Show-GandiKeyValue -Key "Used / Free" -Value "${usedMB}MB used, ${availMB}MB free (${pct}%)" -ValueColor $color
    }
    catch {
        Write-Host "  [!] Gagal membaca info RAM." -ForegroundColor Red
    }

    # Thermal (CPU temp via WMI or fallback)
    Write-Host ""
    Show-GandiBox -Title "THERMAL STATUS"
    try {
        $temps = Get-WmiObject -Namespace "root\WMI" -Class "MSAcpi_ThermalZoneTemperature" -ErrorAction Stop
        foreach ($t in $temps) {
            $tempC = [Math]::Round(($t.CurrentTemperature - 2732) / 10, 1)
            $color = if ($tempC -gt 90) { "Red" } elseif ($tempC -gt 75) { "Yellow" } else { "Green" }
            Show-GandiKeyValue -Key "Thermal Zone" -Value "${tempC} C" -ValueColor $color
        }
    }
    catch {
        Write-Host "  [i] WMI thermal tidak tersedia di sistem ini." -ForegroundColor DarkGray
        Write-Host "  [i] Gunakan HWiNFO64 atau HWMonitor untuk pembacaan suhu akurat." -ForegroundColor DarkGray
    }

    # Pagefile
    Write-Host ""
    Show-GandiBox -Title "PAGEFILE STATUS"
    try {
        $pf = Get-WmiObject -Class Win32_PageFileSetting -ErrorAction SilentlyContinue
        if ($pf) {
            foreach ($p in $pf) {
                Show-GandiKeyValue -Key $p.Name -Value "Init: $($p.InitialSize)MB / Max: $($p.MaximumSize)MB" -ValueColor "White"
            }
        }
        else {
            $cs2 = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
            if ($cs2.AutomaticManagedPagefile) {
                Show-GandiKeyValue -Key "Pagefile" -Value "Auto-managed by Windows" -ValueColor "Yellow"
            }
            else {
                Write-Host "  [i] Tidak ada pagefile terdeteksi." -ForegroundColor DarkGray
            }
        }
    }
    catch { Write-Host "  [!] Gagal membaca pagefile." -ForegroundColor Red }

    Write-Host ""
    Write-Host "  Tekan tombol apapun untuk kembali..." -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}

function Get-MemTweakList {
    $cs = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
    $ramMB = if ($cs) { [Math]::Round($cs.TotalPhysicalMemory / 1MB) } else { 4096 }
    $initMB = [Math]::Round($ramMB * 1.5)
    $maxMB = [Math]::Round($ramMB * 2)
    return @(
        [PSCustomObject]@{ Name = "Pagefile Optimize (1.5x/2x)"; Rec = "safe"; Type = "WMI"; Id = "PAGEFILE_OPT"; Checked = $true; Extra = "$initMB/$maxMB" }
        [PSCustomObject]@{ Name = "ClearPageFile at Shutdown"; Rec = "optional"; Type = "REG"; Id = "CLEAR_PF"; Checked = $false }
        [PSCustomObject]@{ Name = "Memory Compression OFF"; Rec = "optional"; Type = "CMD"; Id = "MEM_COMPRESS"; Checked = $false }
        [PSCustomObject]@{ Name = "Large System Cache ON"; Rec = "optional"; Type = "REG"; Id = "LARGE_CACHE"; Checked = $false }
        [PSCustomObject]@{ Name = "Heap Delay Free OFF"; Rec = "safe"; Type = "REG"; Id = "HEAP_FREE"; Checked = $true }
        [PSCustomObject]@{ Name = "Disable Paging Executive"; Rec = "optional"; Type = "REG"; Id = "EXEC_NO_PAGE"; Checked = $false }
    )
}

function Invoke-MemTweak {
    param($Item)
    try {
        switch ($Item.Id) {
            "PAGEFILE_OPT" {
                $parts = $Item.Extra -split "/"
                $initMB = [int]$parts[0]; $maxMB = [int]$parts[1]
                $cs = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
                $cs.AutomaticManagedPagefile = $false
                $cs.Put() | Out-Null
                $pf = Get-WmiObject -Class Win32_PageFileSetting -ErrorAction SilentlyContinue
                if ($pf) {
                    $pf | ForEach-Object { $_.InitialSize = $initMB; $_.MaximumSize = $maxMB; $_.Put() | Out-Null }
                }
                Write-ActivityLog "PAGEFILE OPTIMIZED: ${initMB}MB / ${maxMB}MB" "OK"
                Write-Host "  [i] Pagefile: ${initMB}MB / ${maxMB}MB" -ForegroundColor Cyan
            }
            "CLEAR_PF" {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Value 1 -Type DWord -ErrorAction Stop
                Write-ActivityLog "CLEAR PAGEFILE AT SHUTDOWN ON" "OK"
            }
            "MEM_COMPRESS" {
                $OSBuild = [System.Environment]::OSVersion.Version.Build
                if ($OSBuild -ge 10240) {
                    Disable-MMAgent -MemoryCompression -ErrorAction Stop
                    Write-ActivityLog "MEMORY COMPRESSION DISABLED" "OK"
                }
                else { Write-Host "  [i] Memory compression hanya tersedia di Windows 10+." -ForegroundColor Yellow }
            }
            "LARGE_CACHE" {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -Type DWord -ErrorAction Stop
                Write-ActivityLog "LARGE SYSTEM CACHE ON" "OK"
            }
            "HEAP_FREE" {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\HeapManager" -Name "HeapDeCommitFreeBlockThreshold" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                Write-ActivityLog "HEAP DELAY FREE OFF" "OK"
            }
            "EXEC_NO_PAGE" {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -ErrorAction Stop
                Write-ActivityLog "PAGING EXECUTIVE DISABLED" "OK"
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
    $Cursor = 0; $Half = 4
    [Console]::Clear()
    while ($true) {
        [Console]::SetCursorPosition(0, 0)
        Show-GandiHeader -Title $Title
        $sel = ($Checked.Values | Where-Object { $_ }).Count
        Show-GandiKeyValue -Key "Total" -Value $Items.Count -ValueColor "White"
        Show-GandiKeyValue -Key "Pilih" -Value $sel -ValueColor "Red"
        Write-Host ""
        for ($i = 0; $i -lt $Half; $i++) {
            $absL = $i
            if ($absL -lt $Items.Count) {
                $li = $Items[$absL]
                $lc = if ($Checked[$absL]) { "[X]" } else { "[ ]" }
                $ln = if ($li.Name.Length -gt 30) { $li.Name.Substring(0, 27) + ".." } else { $li.Name }
                $lf = switch ($li.Rec) { 'safe' { 'White' } 'unsafe' { 'Red' } default { 'Yellow' } }
                $lb = if ($absL -eq $Cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}  " -f $lc, $ln) -ForegroundColor $lf -BackgroundColor $lb -NoNewline
            }
            $absR = $i + $Half
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
                Write-Host "  Apply $($exec.Count) memory tweak? Restart diperlukan. (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-MemTweak -Item $item | Out-Null
                }
                Write-GandiStatus -Status "OK" -Message "Selesai. Restart diperlukan."; Start-Sleep 2; return
            }
        }
    }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 12 MEMORY MANAGEMENT"
    Show-GandiHeader -Title "12 MEMORY MANAGEMENT"
    Write-Host ""
    Write-Host "  [1] Health Check (RAM + Thermal + Pagefile)" -ForegroundColor Cyan
    Write-Host "  [2] Pilih dan Apply Memory Tweaks" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') { Show-SystemHealth }
    elseif ($c -eq '2') {
        Write-ActivityLog "TWEAK INITIATED: #12 - Memory Management"
        Invoke-ChecklistUI "12 MEMORY MANAGEMENT" (Get-MemTweakList)
    }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
