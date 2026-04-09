# encoding: UTF-8
# GandiWin :: 02 Disable Background Services
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
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [02_BG_SERVICES] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

function Get-ServiceTweakList {
    $tweaks = @(
        [PSCustomObject]@{ Name = "DiagTrack (Telemetry)"; Rec = "safe"; Type = "SVC"; Id = "DiagTrack" }
        [PSCustomObject]@{ Name = "dmwappushservice"; Rec = "safe"; Type = "SVC"; Id = "dmwappushservice" }
        [PSCustomObject]@{ Name = "WerSvc (Error Reporting)"; Rec = "safe"; Type = "SVC"; Id = "WerSvc" }
        [PSCustomObject]@{ Name = "WSearch (Indexing)"; Rec = "optional"; Type = "SVC"; Id = "WSearch" }
        [PSCustomObject]@{ Name = "DoSvc (Delivery Optim.)"; Rec = "safe"; Type = "SVC"; Id = "DoSvc" }
        [PSCustomObject]@{ Name = "XblGameSave"; Rec = "safe"; Type = "SVC"; Id = "XblGameSave" }
        [PSCustomObject]@{ Name = "XboxNetApiSvc"; Rec = "safe"; Type = "SVC"; Id = "XboxNetApiSvc" }
        [PSCustomObject]@{ Name = "XblAuthManager"; Rec = "safe"; Type = "SVC"; Id = "XblAuthManager" }
        [PSCustomObject]@{ Name = "Print Spooler"; Rec = "optional"; Type = "SVC"; Id = "Spooler" }
        [PSCustomObject]@{ Name = "Fax"; Rec = "safe"; Type = "SVC"; Id = "Fax" }
        [PSCustomObject]@{ Name = "MapsBroker"; Rec = "safe"; Type = "SVC"; Id = "MapsBroker" }
        [PSCustomObject]@{ Name = "lfsvc (Geolocation)"; Rec = "safe"; Type = "SVC"; Id = "lfsvc" }
        [PSCustomObject]@{ Name = "SharedAccess (ICS)"; Rec = "optional"; Type = "SVC"; Id = "SharedAccess" }
        [PSCustomObject]@{ Name = "RetailDemo"; Rec = "safe"; Type = "SVC"; Id = "RetailDemo" }
        [PSCustomObject]@{ Name = "RemoteRegistry"; Rec = "safe"; Type = "SVC"; Id = "RemoteRegistry" }
        [PSCustomObject]@{ Name = "Hibernation Off"; Rec = "optional"; Type = "CMD"; Id = "HIBERNATION_OFF" }
        [PSCustomObject]@{ Name = "USB Selective Suspend Off"; Rec = "safe"; Type = "REG"; Id = "USB_SS_OFF" }
        [PSCustomObject]@{ Name = "Delivery Optim. OFF (REG)"; Rec = "safe"; Type = "REG"; Id = "DELIVERY_OPT_OFF" }
        [PSCustomObject]@{ Name = "Fast Startup Disable"; Rec = "optional"; Type = "REG"; Id = "FAST_STARTUP_OFF" }
    )
    foreach ($t in $tweaks) { $t | Add-Member -NotePropertyName "Checked" -NotePropertyValue $true -Force }
    return $tweaks
}

function Invoke-ServiceTweak {
    param($Item)
    try {
        if ($Item.Type -eq "SVC") {
            $svc = Get-Service -Name $Item.Id -ErrorAction Stop
            Stop-Service -Name $Item.Id -Force -ErrorAction SilentlyContinue
            Set-Service -Name $Item.Id -StartupType Disabled -ErrorAction Stop
            Write-ActivityLog "DISABLED SVC: $($Item.Id)" "OK"
            return $true
        }
        elseif ($Item.Type -eq "CMD") {
            if ($Item.Id -eq "HIBERNATION_OFF") {
                & powercfg -h off 2>&1 | Out-Null
                Write-ActivityLog "HIBERNATION OFF" "OK"
                return $true
            }
        }
        elseif ($Item.Type -eq "REG") {
            switch ($Item.Id) {
                "USB_SS_OFF" {
                    $path = "HKLM:\SYSTEM\CurrentControlSet\Services\USB"
                    if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                    Set-ItemProperty -Path $path -Name "DisableSelectiveSuspend" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                }
                "DELIVERY_OPT_OFF" {
                    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
                    if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                    Set-ItemProperty -Path $path -Name "DODownloadMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
                "FAST_STARTUP_OFF" {
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
            }
            Write-ActivityLog "APPLIED REG: $($Item.Id)" "OK"
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
    if ($Items.Count -eq 0) { Write-GandiStatus -Status "OK" -Message "Kosong."; Start-Sleep 1; return }
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
        Write-Host "`n  NAV: ARROWS | TOGGLE: SPACE | RESET: N | ALL: A | EXEC: ENTER | ESC: BACK" -ForegroundColor DarkGray
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
                Write-Host "  Eksekusi $($exec.Count) item? (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-ServiceTweak -Item $item | Out-Null
                }
                Write-GandiStatus -Status "OK" -Message "Selesai. Restart dianjurkan."; Start-Sleep 2; return
            }
        }
    }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 02 DISABLE BACKGROUND SERVICES"
    Show-GandiHeader -Title "02 DISABLE BACKGROUND SERVICES"
    Write-Host ""
    Write-Host "  [1] Pilih dan Disable Services" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') {
        Write-ActivityLog "TWEAK INITIATED: #2 - Disable Background Services"
        Invoke-ChecklistUI "02 DISABLE BACKGROUND SERVICES" (Get-ServiceTweakList)
    }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
