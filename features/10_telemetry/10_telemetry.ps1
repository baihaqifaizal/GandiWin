# encoding: UTF-8
# GandiWin :: 10 Telemetry
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
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [10_TELEMETRY] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

function Get-TelemetryTweakList {
    return @(
        [PSCustomObject]@{ Name = "DiagTrack Service OFF"; Rec = "safe"; Type = "SVC"; Id = "DiagTrack"; Checked = $true }
        [PSCustomObject]@{ Name = "dmwappushservice OFF"; Rec = "safe"; Type = "SVC"; Id = "dmwappushservice"; Checked = $true }
        [PSCustomObject]@{ Name = "PcaSvc OFF"; Rec = "safe"; Type = "SVC"; Id = "PcaSvc"; Checked = $true }
        [PSCustomObject]@{ Name = "SysMain (Superfetch) OFF"; Rec = "optional"; Type = "SVC"; Id = "SysMain"; Checked = $false }
        [PSCustomObject]@{ Name = "AllowTelemetry = 0"; Rec = "safe"; Type = "REG"; Id = "TELEMETRY_0"; Checked = $true }
        [PSCustomObject]@{ Name = "CustomerFeedback OFF"; Rec = "safe"; Type = "REG"; Id = "CEI_DISABLE"; Checked = $true }
        [PSCustomObject]@{ Name = "Error Reporting OFF"; Rec = "safe"; Type = "REG"; Id = "WER_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "App Compat Telemetry OFF"; Rec = "safe"; Type = "REG"; Id = "COMPAT_TEL_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "Advertising ID OFF (REG)"; Rec = "safe"; Type = "REG"; Id = "AD_ID_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "Registry Cleanup (Orphans)"; Rec = "optional"; Type = "REG"; Id = "REG_CLEANUP"; Checked = $false }
        [PSCustomObject]@{ Name = "Hosts: Block MS Telemetry"; Rec = "optional"; Type = "HOSTS"; Id = "HOSTS_BLOCK"; Checked = $false }
    )
}

function Invoke-TelemetryTweak {
    param($Item)
    try {
        if ($Item.Type -eq "SVC") {
            $svc = Get-Service -Name $Item.Id -ErrorAction Stop
            Stop-Service -Name $Item.Id -Force -ErrorAction SilentlyContinue
            Set-Service -Name $Item.Id -StartupType Disabled -ErrorAction Stop
            Write-ActivityLog "DISABLED SVC: $($Item.Id)" "OK"
            return $true
        }
        switch ($Item.Id) {
            "TELEMETRY_0" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction Stop
            }
            "CEI_DISABLE" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "CEIPEnable" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            "WER_OFF" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "Disabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            }
            "COMPAT_TEL_OFF" {
                $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\AIT"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "AITEnable" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            "AD_ID_OFF" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                $p2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
                if (!(Test-Path $p2)) { New-Item -Path $p2 -Force | Out-Null }
                Set-ItemProperty -Path $p2 -Name "DisabledByGroupPolicy" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            }
            "REG_CLEANUP" {
                $cleanPaths = @(
                    "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU"
                    "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags"
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU"
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
                )
                foreach ($path in $cleanPaths) {
                    if (Test-Path $path) {
                        Get-ChildItem $path -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
                Write-ActivityLog "REGISTRY ORPHAN CLEANUP DONE" "OK"
            }
            "HOSTS_BLOCK" {
                $hostsPath = "$env:windir\System32\drivers\etc\hosts"
                $telemetryHosts = @(
                    "0.0.0.0 vortex.data.microsoft.com"
                    "0.0.0.0 vortex-win.data.microsoft.com"
                    "0.0.0.0 telecommand.telemetry.microsoft.com"
                    "0.0.0.0 oca.telemetry.microsoft.com"
                    "0.0.0.0 sqm.telemetry.microsoft.com"
                    "0.0.0.0 watson.telemetry.microsoft.com"
                    "0.0.0.0 redir.metaservices.microsoft.com"
                    "0.0.0.0 choice.microsoft.com"
                    "0.0.0.0 df.telemetry.microsoft.com"
                    "0.0.0.0 reports.wes.df.telemetry.microsoft.com"
                    "0.0.0.0 wes.df.telemetry.microsoft.com"
                )
                $existingHosts = Get-Content $hostsPath -ErrorAction SilentlyContinue
                $marker = "# GandiWin Telemetry Block"
                if ($existingHosts -notcontains $marker) {
                    Add-Content -Path $hostsPath -Value "`n$marker" -ErrorAction Stop
                    foreach ($h in $telemetryHosts) {
                        if ($existingHosts -notcontains $h) {
                            Add-Content -Path $hostsPath -Value $h -ErrorAction SilentlyContinue
                        }
                    }
                    Write-ActivityLog "HOSTS TELEMETRY BLOCK APPLIED" "OK"
                }
                else {
                    Write-Host "  [i] Hosts telemetry block sudah ada." -ForegroundColor DarkGray
                }
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
                Write-Host "  Apply $($exec.Count) privacy tweak? (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-TelemetryTweak -Item $item | Out-Null
                }
                Write-GandiStatus -Status "OK" -Message "Selesai."; Start-Sleep 2; return
            }
        }
    }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 10 TELEMETRY"
    Show-GandiHeader -Title "10 TELEMETRY"
    Write-Host ""
    Write-Host "  [1] Pilih dan Apply Telemetry Tweaks" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') {
        Write-ActivityLog "TWEAK INITIATED: #10 - Telemetry"
        Invoke-ChecklistUI "10 TELEMETRY" (Get-TelemetryTweakList)
    }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
