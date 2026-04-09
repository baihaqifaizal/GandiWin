# encoding: UTF-8
# GandiWin :: 09 Apply Quick CPU
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
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [09_QUICKCPU] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

function Get-CPUTweakList {
    $OSBuild = [System.Environment]::OSVersion.Version.Build
    $supportsUltPolicy = $OSBuild -ge 16299
    return @(
        [PSCustomObject]@{ Name = "Ultimate Performance Plan"; Rec = "safe"; Type = "POWER"; Id = "ULTIMATE_PERF"; Checked = $true }
        [PSCustomObject]@{ Name = "CPU Core Unparking"; Rec = "safe"; Type = "REG"; Id = "UNPARK"; Checked = $true }
        [PSCustomObject]@{ Name = "CPU Min State = 100%"; Rec = "safe"; Type = "POWER"; Id = "CPU_MIN_100"; Checked = $true }
        [PSCustomObject]@{ Name = "PageFile Auto-Optimize"; Rec = "safe"; Type = "REG"; Id = "PAGEFILE_AUTO"; Checked = $true }
        [PSCustomObject]@{ Name = "Large System Cache ON"; Rec = "optional"; Type = "REG"; Id = "LARGE_CACHE"; Checked = $false }
        [PSCustomObject]@{ Name = "Spectre/Meltdown Patch OFF"; Rec = "unsafe"; Type = "REG"; Id = "SPECTRE_OFF"; Checked = $false }
        [PSCustomObject]@{ Name = "Timer Resolution Boost"; Rec = "optional"; Type = "REG"; Id = "TIMER_RES"; Checked = $true }
        [PSCustomObject]@{ Name = "HPET Disable (Registry)"; Rec = "optional"; Type = "REG"; Id = "HPET_OFF"; Checked = $false }
    )
}

function Invoke-CPUTweak {
    param($Item)
    try {
        switch ($Item.Id) {
            "ULTIMATE_PERF" {
                $existing = & powercfg /list 2>&1 | Where-Object { $_ -match "Ultimate Performance" }
                if (-not $existing) {
                    & powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-Null
                }
                $schemedLine = & powercfg /list 2>&1 | Where-Object { $_ -match "Ultimate" }
                if ($schemedLine -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
                    $guid = $Matches[1]
                    & powercfg /setactive $guid 2>&1 | Out-Null
                    Write-ActivityLog "ULTIMATE PERFORMANCE ACTIVATED: $guid" "OK"
                }
            }
            "UNPARK" {
                $parkKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
                if (Test-Path $parkKey) {
                    Set-ItemProperty -Path $parkKey -Name "ValueMax" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $parkKey -Name "ValueMin" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                    Write-ActivityLog "CPU UNPARKED" "OK"
                }
            }
            "CPU_MIN_100" {
                # Set CPU minimum processor state to 100% for active power plan
                & powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 2>&1 | Out-Null
                & powercfg /setactive SCHEME_CURRENT 2>&1 | Out-Null
                Write-ActivityLog "CPU MIN STATE = 100%" "OK"
            }
            "PAGEFILE_AUTO" {
                $ram = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory
                $ramMB = [Math]::Round($ram / 1MB)
                $initialMB = [Math]::Round($ramMB * 1.5)
                $maxMB = [Math]::Round($ramMB * 2)
                $cs = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
                $cs.AutomaticManagedPagefile = $false
                $cs.Put() | Out-Null
                $pf = Get-WmiObject -Class Win32_PageFileSetting -ErrorAction SilentlyContinue
                if ($pf) {
                    $pf.InitialSize = $initialMB
                    $pf.MaximumSize = $maxMB
                    $pf.Put() | Out-Null
                }
                else {
                    $newPf = [WMIClass]"Win32_PageFileSetting"
                    $newInst = $newPf.CreateInstance()
                    $newInst.Name = "C:\\pagefile.sys"
                    $newInst.InitialSize = $initialMB
                    $newInst.MaximumSize = $maxMB
                    $newInst.Put() | Out-Null
                }
                Write-ActivityLog "PAGEFILE SET: Init=${initialMB}MB Max=${maxMB}MB" "OK"
                Write-Host "  [i] Pagefile: Initial=${initialMB}MB / Max=${maxMB}MB (RAM=${ramMB}MB)" -ForegroundColor Cyan
            }
            "LARGE_CACHE" {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -Type DWord -ErrorAction Stop
                Write-ActivityLog "LARGE SYSTEM CACHE ON" "OK"
            }
            "SPECTRE_OFF" {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
                Set-ItemProperty -Path $p -Name "FeatureSettingsOverride"     -Value 3 -Type DWord -ErrorAction Stop
                Set-ItemProperty -Path $p -Name "FeatureSettingsOverrideMask"  -Value 3 -Type DWord -ErrorAction Stop
                Write-ActivityLog "SPECTRE/MELTDOWN MITIGATIONS DISABLED" "OK"
                Write-Host "  [!] PERINGATAN: Sistem rentan terhadap exploit CPU. Hanya untuk offline/gaming." -ForegroundColor Red
            }
            "TIMER_RES" {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "GlobalTimerResolutionRequests" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                Write-ActivityLog "TIMER RESOLUTION BOOST ON" "OK"
            }
            "HPET_OFF" {
                & bcdedit /deletevalue useplatformclock 2>&1 | Out-Null
                & bcdedit /set useplatformclock false 2>&1 | Out-Null
                Write-ActivityLog "HPET DISABLED VIA BCDEDIT" "OK"
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
    $Cursor = 0; $Half = 5; $Top = 0
    [Console]::Clear()
    while ($true) {
        [Console]::SetCursorPosition(0, 0)
        Show-GandiHeader -Title $Title
        $sel = ($Checked.Values | Where-Object { $_ }).Count
        Show-GandiKeyValue -Key "Total" -Value $Items.Count -ValueColor "White"
        Show-GandiKeyValue -Key "Pilih" -Value $sel -ValueColor "Red"
        Write-Host "  RED = UNSAFE (hanya untuk gaming/offline)" -ForegroundColor DarkGray
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
                $hasUnsafe = $exec | Where-Object { $_.Rec -eq "unsafe" }
                if ($hasUnsafe) { Write-Host "  [!] ADA TWEAK UNSAFE DIPILIH! Lanjutkan? (YES/NO)" -ForegroundColor Red }
                else { Write-Host "  Apply $($exec.Count) CPU tweak? (YES/NO)" }
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-CPUTweak -Item $item | Out-Null
                }
                Write-GandiStatus -Status "OK" -Message "Selesai. Restart diperlukan."; Start-Sleep 2; return
            }
        }
    }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 09 APPLY QUICK CPU"
    Show-GandiHeader -Title "09 APPLY QUICK CPU"
    Write-Host ""
    $cpuName = (Get-WmiObject -Class Win32_Processor -ErrorAction SilentlyContinue).Name
    if ($cpuName) { Show-GandiKeyValue -Key "CPU" -Value $cpuName.Trim() -ValueColor "Cyan" }
    Write-Host ""
    Write-Host "  [1] Pilih dan Apply CPU Tweaks" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') {
        Write-ActivityLog "TWEAK INITIATED: #9 - Apply Quick CPU"
        Invoke-ChecklistUI "09 APPLY QUICK CPU" (Get-CPUTweakList)
    }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
