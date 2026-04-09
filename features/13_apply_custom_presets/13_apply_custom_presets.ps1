# encoding: UTF-8
# GandiWin :: 13 Apply Custom Presets
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) { Write-Host "[ERROR] PS 5.1+ required!" -ForegroundColor Red; pause; exit 1 }

if ($PSScriptRoot -ne '') { $ScriptDir = $PSScriptRoot }
else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

$UIModule = "$ScriptDir\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

$LogFile = "$ScriptDir\..\..\logs\menu.log"
if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }

$FeaturesDir = "$ScriptDir\..\.."

function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [13_PRESETS] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

$AllFeatures = @(
    @{ Num = 1; Slug = "1_remove_bloatware"; Name = "Remove Bloatware" }
    @{ Num = 2; Slug = "2_disable_bg_services"; Name = "Disable BG Services" }
    @{ Num = 3; Slug = "3_disable_bg_apps"; Name = "Disable BG Apps" }
    @{ Num = 4; Slug = "4_disable_task_scheduler"; Name = "Disable Task Scheduler" }
    @{ Num = 5; Slug = "5_disable_startup_apps"; Name = "Disable Startup Apps" }
    @{ Num = 6; Slug = "6_portable_antivirus"; Name = "Portable Antivirus" }
    @{ Num = 7; Slug = "7_everything_search"; Name = "Everything Search" }
    @{ Num = 8; Slug = "8_apply_visual_effects"; Name = "Apply Visual Effects" }
    @{ Num = 9; Slug = "9_apply_quick_cpu"; Name = "Apply Quick CPU" }
    @{ Num = 10; Slug = "10_telemetry"; Name = "Telemetry" }
    @{ Num = 11; Slug = "11_disk"; Name = "Disk" }
    @{ Num = 12; Slug = "12_memory_management"; Name = "Memory Management" }
)

$Presets = @(
    [PSCustomObject]@{
        Name    = "Gaming PC"
        Desc    = "Remove bloat + disable BG + visual FX + CPU tweak"
        Modules = @(1, 2, 3, 5, 8, 9)
        Checked = $true
    }
    [PSCustomObject]@{
        Name    = "Office / Work PC"
        Desc    = "Disable BG + tasks + startup + search + telemetry + disk"
        Modules = @(2, 3, 4, 5, 7, 10, 11)
        Checked = $false
    }
    [PSCustomObject]@{
        Name    = "Privacy First"
        Desc    = "Disable startup + change AV + block telemetry"
        Modules = @(4, 5, 6, 10)
        Checked = $false
    }
    [PSCustomObject]@{
        Name    = "Full Optimization"
        Desc    = "Semua 12 metode dijalankan berurutan"
        Modules = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
        Checked = $false
    }
    [PSCustomObject]@{
        Name    = "Maintenance Rutin"
        Desc    = "Disk cleanup + memory check + task scheduler"
        Modules = @(4, 11, 12)
        Checked = $false
    }
)

function Invoke-LaunchModule {
    param([int]$Num)
    $feat = $AllFeatures | Where-Object { $_.Num -eq $Num }
    if (-not $feat) {
        Write-GandiStatus -Status "WARN" -Message "Modul #$Num tidak ditemukan."
        return
    }
    $scriptPath = Join-Path $FeaturesDir "features\$($feat.Slug)\$($feat.Slug).ps1"
    if (Test-Path $scriptPath) {
        Write-GandiStatus -Status "WAIT" -Message "Launching: $($feat.Name) (#$Num)..."
        Write-ActivityLog "PRESET LAUNCHED MODULE: #$Num $($feat.Name)" "OK"
        Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`"" -Wait
    }
    else {
        Write-GandiStatus -Status "FAIL" -Message "Script tidak ditemukan: $scriptPath"
        Write-ActivityLog "MISSING MODULE: $scriptPath" "FAIL"
    }
}

function Show-PresetMenu {
    $cursor = 0
    [Console]::Clear()
    while ($true) {
        [Console]::SetCursorPosition(0, 0)
        Show-GandiHeader -Title "13 APPLY CUSTOM PRESETS"
        Write-Host "  Pilih preset konfigurasi:" -ForegroundColor White
        Write-Host ""
        for ($i = 0; $i -lt $Presets.Count; $i++) {
            $p = $Presets[$i]
            $lb = if ($i -eq $cursor) { 'DarkCyan' } else { 'Black' }
            $mods = ($p.Modules | ForEach-Object { "#$_" }) -join ", "
            Write-Host ("  [{0}] {1,-22} {2}" -f ($i + 1), $p.Name, $p.Desc) -ForegroundColor White -BackgroundColor $lb
            Write-Host ("       Modul: {0}" -f $mods) -ForegroundColor DarkGray -BackgroundColor $lb
            Write-Host ""
        }
        Write-Host "  [C] Custom pilih modul sendiri" -ForegroundColor Yellow
        Write-Host "  [ESC] Kembali" -ForegroundColor DarkGray
        $k = [Console]::ReadKey($true)
        switch ($k.Key) {
            'UpArrow' { if ($cursor -gt 0) { $cursor-- } }
            'DownArrow' { if ($cursor -lt ($Presets.Count - 1)) { $cursor++ } }
            'Enter' {
                $selected = $Presets[$cursor]
                [Console]::Clear()
                Show-GandiHeader -Title "PRESET: $($selected.Name)"
                Write-Host "  $($selected.Desc)" -ForegroundColor Cyan
                Write-Host "  Modul: $(($selected.Modules | ForEach-Object { "#$_" }) -join ', ')" -ForegroundColor White
                Write-Host ""
                Write-Host "  Jalankan preset ini? (YES/NO)" -ForegroundColor Yellow
                if ((Read-Host "  CMD") -eq 'YES') {
                    Write-ActivityLog "PRESET STARTED: $($selected.Name)" "INFO"
                    foreach ($modNum in $selected.Modules) {
                        $feat = $AllFeatures | Where-Object { $_.Num -eq $modNum }
                        Write-GandiStatus -Status "INFO" -Message "Antrian: #$modNum - $($feat.Name)"
                    }
                    Write-Host ""
                    Write-Host "  Setiap modul akan dibuka satu per satu." -ForegroundColor DarkGray
                    Write-Host "  Tutup modul setelah selesai untuk buka berikutnya." -ForegroundColor DarkGray
                    pause
                    foreach ($modNum in $selected.Modules) {
                        Invoke-LaunchModule -Num $modNum
                    }
                    Write-ActivityLog "PRESET COMPLETED: $($selected.Name)" "OK"
                    Write-GandiStatus -Status "OK" -Message "Semua modul preset selesai."
                    Start-Sleep 2
                }
                [Console]::Clear()
                return
            }
            'C' {
                Invoke-CustomPreset
                return
            }
            'Escape' { return }
        }
    }
}

function Invoke-CustomPreset {
    $Checked = @{}
    for ($i = 0; $i -lt $AllFeatures.Count; $i++) { $Checked[$i] = $false }
    $cursor = 0; $Half = 6
    [Console]::Clear()
    while ($true) {
        [Console]::SetCursorPosition(0, 0)
        Show-GandiHeader -Title "13 CUSTOM PRESET"
        $sel = ($Checked.Values | Where-Object { $_ }).Count
        Show-GandiKeyValue -Key "Dipilih" -Value $sel -ValueColor "Red"
        Write-Host ""
        for ($i = 0; $i -lt $Half; $i++) {
            $absL = $i
            if ($absL -lt $AllFeatures.Count) {
                $f = $AllFeatures[$absL]
                $lc = if ($Checked[$absL]) { "[X]" } else { "[ ]" }
                $ln = ("#$($f.Num) $($f.Name)").Substring(0, [Math]::Min(("#{0} {1}" -f $f.Num, $f.Name).Length, 30))
                $lb = if ($absL -eq $cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}  " -f $lc, $ln) -ForegroundColor White -BackgroundColor $lb -NoNewline
            }
            $absR = $i + $Half
            if ($absR -lt $AllFeatures.Count) {
                $f = $AllFeatures[$absR]
                $rc = if ($Checked[$absR]) { "[X]" } else { "[ ]" }
                $rn = ("#$($f.Num) $($f.Name)").Substring(0, [Math]::Min(("#{0} {1}" -f $f.Num, $f.Name).Length, 30))
                $rb = if ($absR -eq $cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}" -f $rc, $rn) -ForegroundColor White -BackgroundColor $rb
            }
            else { Write-Host "".PadRight(40) }
        }
        Write-Host "`n  NAV: ARROWS | TOGGLE: SPACE | ALL: A | RESET: N | RUN: ENTER | ESC: BACK" -ForegroundColor DarkGray
        $k = [Console]::ReadKey($true)
        switch ($k.Key) {
            'UpArrow' { if ($cursor -gt 0) { $cursor-- } }
            'DownArrow' { if ($cursor -lt ($AllFeatures.Count - 1)) { $cursor++ } }
            'LeftArrow' { if ($cursor -ge $Half) { $cursor -= $Half } }
            'RightArrow' { if ($cursor + $Half -lt $AllFeatures.Count) { $cursor += $Half } }
            'Spacebar' { $Checked[$cursor] = -not $Checked[$cursor] }
            'A' { 0..($AllFeatures.Count - 1) | ForEach-Object { $Checked[$_] = $true } }
            'N' { 0..($AllFeatures.Count - 1) | ForEach-Object { $Checked[$_] = $false } }
            'Escape' { return }
            'Enter' {
                $selectedNums = 0..($AllFeatures.Count - 1) | Where-Object { $Checked[$_] } | ForEach-Object { $AllFeatures[$_].Num }
                if ($selectedNums.Count -eq 0) { continue }
                [Console]::Clear(); Show-GandiHeader -Title "KONFIRMASI CUSTOM PRESET"
                Write-Host "  Jalankan $($selectedNums.Count) modul? (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                Write-ActivityLog "CUSTOM PRESET STARTED: Modul $($selectedNums -join ',')" "INFO"
                Write-Host ""
                Write-Host "  Setiap modul akan dibuka satu per satu." -ForegroundColor DarkGray
                Write-Host "  Tutup modul setelah selesai untuk buka berikutnya." -ForegroundColor DarkGray
                pause
                foreach ($num in $selectedNums) { Invoke-LaunchModule -Num $num }
                Write-ActivityLog "CUSTOM PRESET COMPLETED" "OK"
                Write-GandiStatus -Status "OK" -Message "Selesai."; Start-Sleep 2; return
            }
        }
    }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 13 APPLY CUSTOM PRESETS"
    Show-GandiHeader -Title "13 APPLY CUSTOM PRESETS"
    Write-Host ""
    Write-Host "  [1] Pilih Preset" -ForegroundColor White
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') {
        Write-ActivityLog "TWEAK INITIATED: #13 - Apply Custom Presets"
        Show-PresetMenu
    }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
