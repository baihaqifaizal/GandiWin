# encoding: UTF-8
# GandiWin :: 08 Apply Visual Effects
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
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [08_VISUAL] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

$WinAPI = @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")] public static extern bool SystemParametersInfo(int uAction, int uParam, int[] lpvParam, int fuWinIni);
    [DllImport("user32.dll")] public static extern bool SystemParametersInfo(int uAction, int uParam, bool lpvParam, int fuWinIni);
}
"@
try { Add-Type -TypeDefinition $WinAPI -ErrorAction SilentlyContinue } catch {}

function Get-VisualTweakList {
    return @(
        [PSCustomObject]@{ Name = "Best Performance (All VFX OFF)"; Rec = "safe"; Type = "VFX"; Id = "VFX_PERF"; Checked = $true }
        [PSCustomObject]@{ Name = "Smooth Fonts Keep"; Rec = "optional"; Type = "VFX"; Id = "VFX_FONTS"; Checked = $true }
        [PSCustomObject]@{ Name = "Thumbnails Keep"; Rec = "optional"; Type = "VFX"; Id = "VFX_THUMB"; Checked = $true }
        [PSCustomObject]@{ Name = "Mouse Pointer Precision OFF"; Rec = "safe"; Type = "REG"; Id = "MOUSE_PREC"; Checked = $true }
        [PSCustomObject]@{ Name = "GPU HAGS Enable"; Rec = "optional"; Type = "REG"; Id = "GPU_HAGS"; Checked = $true }
        [PSCustomObject]@{ Name = "MSI Mode GPU/NIC"; Rec = "optional"; Type = "REG"; Id = "MSI_MODE"; Checked = $false }
        [PSCustomObject]@{ Name = "DWM Animation Disable"; Rec = "safe"; Type = "REG"; Id = "DWM_ANIM"; Checked = $true }
        [PSCustomObject]@{ Name = "Transparency Effects OFF"; Rec = "safe"; Type = "REG"; Id = "TRANSPARENT_OFF"; Checked = $true }
        [PSCustomObject]@{ Name = "Focus Assist (DnD) ON"; Rec = "optional"; Type = "REG"; Id = "FOCUS_ASSIST"; Checked = $false }
    )
}

function Invoke-VisualTweak {
    param($Item)
    try {
        switch ($Item.Id) {
            "VFX_PERF" {
                # SPI_SETVISUALFXPOLICY = 0x1048, value 2 = best performance
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
                if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
                Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction Stop
                # Also set via UserPreferencesMask
                $upmPath = "HKCU:\Control Panel\Desktop"
                Set-ItemProperty -Path $upmPath -Name "UserPreferencesMask" -Value ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) -ErrorAction SilentlyContinue
            }
            "VFX_FONTS" {
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Value "2" -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothingType" -Value 2 -Type DWord -ErrorAction SilentlyContinue
            }
            "VFX_THUMB" {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "IconsOnly" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            "MOUSE_PREC" {
                Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -ErrorAction SilentlyContinue
            }
            "GPU_HAGS" {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "HwSchMode" -Value 2 -Type DWord -ErrorAction Stop
            }
            "MSI_MODE" {
                # Enable MSI for GPU and NIC via registry
                $devPaths = @()
                try { $devPaths += (Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI" -ErrorAction SilentlyContinue).PSPath } catch {}
                foreach ($devBase in $devPaths) {
                    try {
                        $devItems = Get-ChildItem $devBase -ErrorAction SilentlyContinue
                        foreach ($devItem in $devItems) {
                            $msiPath = "$($devItem.PSPath)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
                            if (Test-Path $msiPath) {
                                Set-ItemProperty -Path $msiPath -Name "MSISupported" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                            }
                        }
                    }
                    catch {}
                }
            }
            "DWM_ANIM" {
                $p = "HKCU:\Software\Microsoft\Windows\DWM"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "Animations" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MinAnimate" -Value "0" -ErrorAction SilentlyContinue
            }
            "TRANSPARENT_OFF" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
                if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name "EnableTransparency" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
            "FOCUS_ASSIST" {
                $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default`$windows.data.notifications.quietmodesettings"
                # Focus Assist set via registry is read-only; use API
                Write-Host "  [i] Focus Assist harus diset manual: Settings > System > Focus Assist" -ForegroundColor Yellow
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
    $Cursor = 0; $Half = 5; $Top = 0
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
                Write-Host "  Apply $($exec.Count) visual tweak? (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-VisualTweak -Item $item | Out-Null
                }
                Write-GandiStatus -Status "OK" -Message "Selesai. Sign-out/restart untuk efek penuh."; Start-Sleep 2; return
            }
        }
    }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 08 APPLY VISUAL EFFECTS"
    Show-GandiHeader -Title "08 APPLY VISUAL EFFECTS"
    Write-Host ""
    Write-Host "  [1] Pilih dan Apply Visual Tweaks" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') {
        Write-ActivityLog "TWEAK INITIATED: #8 - Apply Visual Effects"
        Invoke-ChecklistUI "08 APPLY VISUAL EFFECTS" (Get-VisualTweakList)
    }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
