# GandiWin Universal Menu
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    pause
    exit 1
}

$UIModule = "$PSScriptRoot\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

Set-GandiConsole -Title "GANDIWIN :: CONTROL CENTER"

$ModulesDir = "$PSScriptRoot\modules"
$LogsDir = "$PSScriptRoot\logs"
$FeaturesDir = "$PSScriptRoot\features"
$ActivityLog = "$LogsDir\menu.log"

if (!(Test-Path $ModulesDir)) { New-Item -ItemType Directory -Path $ModulesDir  -Force | Out-Null }
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir     -Force | Out-Null }
if (!(Test-Path $FeaturesDir)) { New-Item -ItemType Directory -Path $FeaturesDir -Force | Out-Null }

function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try { Add-Content -Path $ActivityLog -Value "[$ts] [$Level] [UNIVERSAL_MENU] $Message" -ErrorAction SilentlyContinue } catch {}
}

$Features = @(
    @{ Num = 1; Name = "Remove Bloatware"; Slug = "1_remove_bloatware" }
    @{ Num = 2; Name = "Disable BG Services"; Slug = "2_disable_bg_services" }
    @{ Num = 3; Name = "Disable BG Apps"; Slug = "3_disable_bg_apps" }
    @{ Num = 4; Name = "Disable Task Scheduler"; Slug = "4_disable_task_scheduler" }
    @{ Num = 5; Name = "Disable Startup Apps"; Slug = "5_disable_startup_apps" }
    @{ Num = 6; Name = "Portable Antivirus"; Slug = "6_portable_antivirus" }
    @{ Num = 7; Name = "Everything Search"; Slug = "7_everything_search" }
    @{ Num = 8; Name = "Apply Visual Effects"; Slug = "8_apply_visual_effects" }
    @{ Num = 9; Name = "Apply Quick CPU"; Slug = "9_apply_quick_cpu" }
    @{ Num = 10; Name = "Telemetry"; Slug = "10_telemetry" }
    @{ Num = 11; Name = "Disk"; Slug = "11_disk" }
    @{ Num = 12; Name = "Memory Management"; Slug = "12_memory_management" }
    @{ Num = 13; Name = "Apply Custom Presets"; Slug = "13_apply_custom_presets" }
)

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: CONTROL CENTER"
    Show-GandiBanner

    Show-GandiBox -Title "FEATURES DIRECTORY"
    Write-Host ""

    for ($i = 0; $i -lt $Features.Count; $i += 2) {
        $Num1 = $Features[$i].Num.ToString("00")
        $Name1 = $Features[$i].Name.PadRight(25)

        Write-Host "  [" -NoNewline -ForegroundColor DarkGray
        Write-Host $Num1 -NoNewline -ForegroundColor Yellow
        Write-Host "] " -NoNewline -ForegroundColor DarkGray
        Write-Host $Name1 -NoNewline -ForegroundColor Cyan

        if ($i + 1 -lt $Features.Count) {
            $Num2 = $Features[$i + 1].Num.ToString("00")
            $Name2 = $Features[$i + 1].Name

            Write-Host "  [" -NoNewline -ForegroundColor DarkGray
            Write-Host $Num2 -NoNewline -ForegroundColor Yellow
            Write-Host "] " -NoNewline -ForegroundColor DarkGray
            if ($Features[$i + 1].Num -eq 13) {
                Write-Host $Name2 -ForegroundColor Magenta
            }
            else {
                Write-Host $Name2 -ForegroundColor Cyan
            }
        }
        else {
            Write-Host ""
        }
    }

    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host "  [13] APPLY CUSTOM PRESETS    [R] REFRESH    [Q] DEACTIVATE" -ForegroundColor Yellow
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""

    $Choice = Read-Host "  AWAITING COMMAND (1-13)"

    if ($Choice -eq "Q") {
        Invoke-GandiTypewriter -Text "SHUTTING DOWN TERMINAL..." -DelayMs 10 -Color Red
        pause; exit
    }
    if ($Choice -eq "R") { continue }

    if ($Choice -match "^\d+$") {
        $Num = [int]$Choice
        if ($Num -ge 1 -and $Num -le 13) {
            $Feature = $Features | Where-Object { $_.Num -eq $Num }
            $ScriptPath = Join-Path $FeaturesDir "$($Feature.Slug)\$($Feature.Slug).ps1"
            Write-ActivityLog "TWEAK INITIATED: #$Num - $($Feature.Name)"

            if (Test-Path $ScriptPath) {
                Write-GandiStatus -Status "OK" -Message "Executing module $($Feature.Slug)"
                Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`""
            }
            else {
                Write-GandiStatus -Status "FAIL" -Message "Module script missing: $ScriptPath"
                Start-Sleep -Seconds 2
            }
        }
    }
}
