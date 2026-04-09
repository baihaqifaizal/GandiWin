# encoding: UTF-8
# GandiWin :: 03 Disable Background Apps
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
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [03_BG_APPS] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

function Get-BgAppTweakList {
    return @(
        [PSCustomObject]@{ Name = "Global Background Apps OFF"; Rec = "safe"; Type = "REG"; Id = "BG_APPS_GLOBAL_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "Nagle Algorithm Disable"; Rec = "safe"; Type = "REG"; Id = "NAGLE_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "Network Throttling OFF"; Rec = "safe"; Type = "REG"; Id = "NET_THROTTLE_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "Activity History OFF"; Rec = "safe"; Type = "REG"; Id = "ACTIVITY_HIST_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "Cortana Search OFF"; Rec = "optional"; Type = "REG"; Id = "CORTANA_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "Suggested Content OFF"; Rec = "safe"; Type = "REG"; Id = "SUGGESTED_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "Advertising ID OFF"; Rec = "safe"; Type = "REG"; Id = "AD_ID_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "Windows Ink OFF"; Rec = "optional"; Type = "REG"; Id = "INK_OFF"; Checked = $false }
        [PSCustomObject]@{ Name = "App Notification Access OFF"; Rec = "safe"; Type = "REG"; Id = "NOTIF_ACCESS_OFF"; Checked = $true }
    )
}

function Invoke-BgAppTweak {
    param($Item)
    try {
        switch ($Item.Id) {
            "BG_APPS_GLOBAL_OFF" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "GlobalUserDisabled" -Value 1 -Type DWord -ErrorAction Stop
                Set-ItemProperty -Path $p -Name "Disabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            }
            "NAGLE_OFF" {
                $baseKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
                if (Test-Path $baseKey) {
                    Get-ChildItem $baseKey -ErrorAction SilentlyContinue | ForEach-Object {
                        Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay"      -Value 1 -Type DWord -ErrorAction SilentlyContinue
                    }
                }
                $p2 = "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters"
                if (!(Test-Path $p2)) { New-Item -Path $p2 -Force | Out-Null }
                Set-ItemProperty -Path $p2 -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            }
            "NET_THROTTLE_OFF" {
                $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -ErrorAction Stop
                Set-ItemProperty -Path $p -Name "SystemResponsiveness"   -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            "ACTIVITY_HIST_OFF" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "EnableActivityFeed"   -Value 0 -Type DWord -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $p -Name "PublishUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            "CORTANA_OFF" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "AllowCortana" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            "SUGGESTED_OFF" {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value 0 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Value 0 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled" -Value 0 -ErrorAction SilentlyContinue
            }
            "AD_ID_OFF" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            "INK_OFF" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "AllowWindowsInkWorkspace" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            "NOTIF_ACCESS_OFF" {
                $p = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "Value" -Value "Deny" -ErrorAction SilentlyContinue
            }
        }
        Write-ActivityLog "APPLIED: $($Item.Id)" "OK"
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
                Write-Host "  Eksekusi $($exec.Count) item? (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-BgAppTweak -Item $item | Out-Null
                }
                Write-GandiStatus -Status "OK" -Message "Selesai."; Start-Sleep 2; return
            }
        }
    }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 03 DISABLE BACKGROUND APPS"
    Show-GandiHeader -Title "03 DISABLE BACKGROUND APPS"
    Write-Host ""
    Write-Host "  [1] Pilih dan Apply Tweak" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') {
        Write-ActivityLog "TWEAK INITIATED: #3 - Disable Background Apps"
        Invoke-ChecklistUI "03 DISABLE BACKGROUND APPS" (Get-BgAppTweakList)
    }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
