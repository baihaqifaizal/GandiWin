# encoding: UTF-8
# GandiWin :: 04 Disable Task Scheduler
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
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [04_TASK_SCHED] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

function Get-ScheduledTaskTweakList {
    $tasks = @(
        @{ Name = "Compatibility Appraiser"; Path = "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"; Rec = "safe" }
        @{ Name = "ProgramDataUpdater"; Path = "\Microsoft\Windows\Application Experience\ProgramDataUpdater"; Rec = "safe" }
        @{ Name = "AitAgent"; Path = "\Microsoft\Windows\Application Experience\AitAgent"; Rec = "safe" }
        @{ Name = "CEIP Consolidator"; Path = "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"; Rec = "safe" }
        @{ Name = "KernelCeipTask"; Path = "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"; Rec = "safe" }
        @{ Name = "UsbCeip"; Path = "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"; Rec = "safe" }
        @{ Name = "Maintenance WindowsUpdate"; Path = "\Microsoft\Windows\UpdateOrchestrator\Maintenance Installer"; Rec = "optional" }
        @{ Name = "WinSAT (Windows Score)"; Path = "\Microsoft\Windows\Maintenance\WinSAT"; Rec = "safe" }
        @{ Name = "FamilySafetyMonitor"; Path = "\Microsoft\Windows\Shell\FamilySafetyMonitor"; Rec = "safe" }
        @{ Name = "FamilySafetyRefresh"; Path = "\Microsoft\Windows\Shell\FamilySafetyRefreshTask"; Rec = "safe" }
        @{ Name = "SmartScreenSpec"; Path = "\Microsoft\Windows\AppID\SmartScreenSpecific"; Rec = "optional" }
        @{ Name = "Maps Toast Task"; Path = "\Microsoft\Windows\Maps\MapsToastTask"; Rec = "safe" }
        @{ Name = "Maps Update Task"; Path = "\Microsoft\Windows\Maps\MapsUpdateTask"; Rec = "safe" }
        @{ Name = "Xbox Cloud Save"; Path = "\Microsoft\XblGameSave\XblGameSaveTask"; Rec = "safe" }
        @{ Name = "MSDT (Diag. Tool)"; Path = "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"; Rec = "optional" }
        @{ Name = "AutoWake (Network)"; Path = "\Microsoft\Windows\SideShow\AutoWake"; Rec = "safe" }
    )
    $result = @()
    foreach ($t in $tasks) {
        $result += [PSCustomObject]@{ Name = $t.Name; Rec = $t.Rec; Path = $t.Path; Checked = $true }
    }
    return $result
}

function Invoke-DisableTask {
    param($Item)
    try {
        $task = Get-ScheduledTask -TaskPath (Split-Path $Item.Path -Parent) -TaskName (Split-Path $Item.Path -Leaf) -ErrorAction Stop
        Disable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null
        Write-ActivityLog "DISABLED TASK: $($Item.Name)" "OK"
        return $true
    }
    catch {
        Write-ActivityLog "SKIP/FAIL: $($Item.Name) - $($_.Exception.Message)" "FAIL"
        Write-Host "  [!] Melewati $($Item.Name) (Tidak didukung di sistem ini)..." -ForegroundColor Yellow
        return $false
    }
}

function Invoke-ChecklistUI {
    param([string]$Title, [array]$Items)
    if ($Items.Count -eq 0) { Write-GandiStatus -Status "OK" -Message "Kosong."; Start-Sleep 1; return }
    $Checked = @{}
    for ($i = 0; $i -lt $Items.Count; $i++) { $Checked[$i] = $Items[$i].Checked }
    $Cursor = 0; $Half = 9; $Top = 0
    [Console]::Clear()
    while ($true) {
        if ($Cursor -lt $Top) { $Top = $Cursor }
        if ($Cursor -ge ($Top + 18)) { $Top = $Cursor - 17 }
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
                Write-Host "  Disable $($exec.Count) scheduled task? (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-DisableTask -Item $item | Out-Null
                }
                Write-GandiStatus -Status "OK" -Message "Selesai."; Start-Sleep 2; return
            }
        }
    }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 04 DISABLE TASK SCHEDULER"
    Show-GandiHeader -Title "04 DISABLE TASK SCHEDULER"
    Write-Host ""
    Write-Host "  [1] Pilih dan Disable Scheduled Tasks" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') {
        Write-ActivityLog "TWEAK INITIATED: #4 - Disable Task Scheduler"
        Invoke-ChecklistUI "04 DISABLE TASK SCHEDULER" (Get-ScheduledTaskTweakList)
    }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
