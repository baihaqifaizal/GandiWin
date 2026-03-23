# WAJIB ada di setiap script utama
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red; pause; exit 1
}

if ($PSScriptRoot -ne '') { $ScriptDir = $PSScriptRoot }
else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

$UIModule = "$ScriptDir\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

$LogFile = "$ScriptDir\..\..\logs\menu.log"
$AppsJson = "$ScriptDir\Config\Apps.json"
$ProgressPreference = 'SilentlyContinue'

function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [3_BLOATWARE] $Message" -ErrorAction SilentlyContinue } catch {}
}

# =============================================================================
# DATA LOADERS
# =============================================================================
function Get-BloatwareList {
    if (-not (Test-Path $AppsJson)) { return @() }
    $raw = Get-Content -Path $AppsJson -Raw | ConvertFrom-Json
    $installed = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $result = @()
    foreach ($app in $raw.Apps) {
        $found = $installed | Where-Object { $_ -like "*$($app.AppId)*" }
        if ($found) {
            $result += [PSCustomObject]@{
                Name    = $app.FriendlyName
                AppId   = $app.AppId
                Rec     = $app.Recommendation
                Checked = ($app.SelectedByDefault -and $app.Recommendation -eq 'safe')
                Type    = 'AppX'
            }
        }
    }
    return $result
}

function Get-InstalledAppList {
    $result = @()
    $appx = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    foreach ($a in $appx) {
        if ($a.Name -match '^(Microsoft\.UI|Microsoft\.VCLibs|Microsoft\.NET|Windows\.|winstore)') { continue }
        $result += [PSCustomObject]@{
            Name         = if ($a.Name.Length -gt 40) { $a.Name.Substring(0, 40) } else { $a.Name }
            AppId        = $a.PackageFullName
            Rec          = 'optional'
            Checked      = $false
            Type         = 'AppX'
            UninstallStr = ''
        }
    }
    $regPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($path in $regPaths) {
        $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and -not $_.SystemComponent -and $_.UninstallString }
        foreach ($a in $apps) {
            $name = $a.DisplayName
            if ($name.Length -gt 40) { $name = $name.Substring(0, 40) }
            $result += [PSCustomObject]@{
                Name         = $name
                AppId        = $a.PSChildName
                Rec          = 'optional'
                Checked      = $false
                Type         = 'Win32'
                UninstallStr = $a.UninstallString
                InstallLoc   = $a.InstallLocation
            }
        }
    }
    return $result | Sort-Object Name -Unique
}

# =============================================================================
# REMOVAL LOGIC
# =============================================================================
function Remove-AppItem {
    param($Item, $DeepClean)
    $success = $false
    try {
        if ($Item.Type -eq 'AppX') {
            $p = "*$($Item.AppId)*"
            Get-AppxPackage -Name $p -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $p } | ForEach-Object { Remove-AppxProvisionedPackage -Online -AllUsers -PackageName $_.PackageName -ErrorAction SilentlyContinue }
            $success = $true
        }
        else {
            $u = $Item.UninstallStr
            if ($u -match 'msiexec') { $u = $u -replace '/I', '/X' + ' /qn' }
            elseif ($u -notmatch '/S') { $u += ' /S' }
            $parts = $u -split ' ', 2
            $exe = $parts[0].Trim('"')
            $args = if ($parts.Count -gt 1) { $parts[1] } else { '' }
            if (Test-Path $exe) { 
                $proc = Start-Process $exe $args -Wait -PassThru -ErrorAction SilentlyContinue
                $success = ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010)
            }
        }
        if ($success -and $DeepClean) {
            $n = ($Item.Name -split ' ')[0]
            @( "$env:ProgramFiles\$n", "$env:LOCALAPPDATA\$n", "$env:APPDATA\$n" ) | ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue } }
        }
    }
    catch {}
    return $success
}

# =============================================================================
# INTERACTIVE UI
# =============================================================================
function Invoke-ChecklistUI {
    param([string]$Title, [array]$Items, [bool]$Deep)
    if ($Items.Count -eq 0) { Write-GandiStatus -Status "OK" -Message "Kosong."; Start-Sleep 1; return }

    $Checked = @{}; for ($i = 0; $i -lt $Items.Count; $i++) { $Checked[$i] = $Items[$i].Checked }
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
        
        $slice = $Items[$Top..($Top + $Vis - 1)]
        for ($i = 0; $i -lt $Half; $i++) {
            $LIdx = $i; $RIdx = $i + $Half
            # Left
            $absL = $Top + $LIdx
            if ($absL -lt $Items.Count) {
                $li = $Items[$absL]
                $lc = if ($Checked[$absL]) { "[X]" } else { "[ ]" }
                $ln = if ($li.Name.Length -gt 30) { $li.Name.Substring(0, 27) + ".." } else { $li.Name }
                $lf = switch ($li.Rec) { 'safe' { 'White' }'unsafe' { 'Red' }default { 'Yellow' } }
                $lb = if ($absL -eq $Cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}  " -f $lc, $ln) -ForegroundColor $lf -BackgroundColor $lb -NoNewline
            }
            # Right
            $absR = $Top + $RIdx
            if ($absR -lt $Items.Count) {
                $ri = $Items[$absR]
                $rc = if ($Checked[$absR]) { "[X]" } else { "[ ]" }
                $rn = if ($ri.Name.Length -gt 30) { $ri.Name.Substring(0, 27) + ".." } else { $ri.Name }
                $rf = switch ($ri.Rec) { 'safe' { 'White' }'unsafe' { 'Red' }default { 'Yellow' } }
                $rb = if ($absR -eq $Cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}" -f $rc, $rn) -ForegroundColor $rf -BackgroundColor $rb
            }
            else { Write-Host "" }
        }

        Write-Host "`n  NAV: ARROWS | TOGGLE: SPACE | RESET: N | ALL: A | EXEC: ENTER | ESC: BACK" -ForegroundColor DarkGray
        $k = [Console]::ReadKey($true)
        switch ($k.Key) {
            'UpArrow' { if ($Cursor -gt 0) { $Cursor-- } }
            'DownArrow' { if ($Cursor -lt ($Items.Count - 1)) { $Cursor++ } }
            'LeftArrow' { if ($Cursor -ge $Half) { $Cursor -= $Half } }
            'RightArrow' { if ($Cursor + $Half -lt $Items.Count) { $Cursor += $Half } }
            'Spacebar' { $Checked[$Cursor] = -not $Checked[$Cursor] }
            'A' { 0..($Items.Count - 1) | % { $Checked[$_] = $true } }
            'N' { 0..($Items.Count - 1) | % { $Checked[$_] = $false } }
            'Escape' { return }
            'Enter' {
                $exec = 0..($Items.Count - 1) | ? { $Checked[$_] } | % { $Items[$_] }
                if ($exec.Count -eq 0) { continue }
                [Console]::Clear(); Show-GandiHeader -Title "KONFIRMASI"; Write-Host "  Hapus $($exec.Count) aplikasi? (YES/NO)"; if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($a in $exec) { Write-GandiStatus -Status "WAIT" -Message "Hapus: $($a.Name)"; Remove-AppItem $a $Deep | Out-Null }
                Write-GandiStatus -Status "OK" -Message "Selesai."; Start-Sleep 2; return
            }
        }
    }
}

# =============================================================================
# MAIN
# =============================================================================
while ($true) {
    [Console]::Clear(); Set-GandiConsole -Title "GANDIWIN"
    Show-GandiHeader -Title "03 BLOATWARE REMOVAL"
    Write-Host "`n  [1] Bloatware List (Safe)`n  [2] Custom App Removal (Deep Clean)`n`n  [Q] Keluar"
    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') { Invoke-ChecklistUI "BLOATWARE" (Get-BloatwareList) $false }
    elseif ($c -eq '2') { Invoke-ChecklistUI "DEEP CLEAN" (Get-InstalledAppList) $true }
    elseif ($c -eq 'Q') { exit }
}
