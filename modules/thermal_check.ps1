<#
.SYNOPSIS
    Thermal Check - Monitor CPU/GPU temperatures
#>

[Console]::Title = "GANDIWIN :: THERMAL CHECK"
[Console]::BackgroundColor = "Black"
[Console]::ForegroundColor = "Green"
Clear-Host

$Script:LogsDir = "$PSScriptRoot\..\logs"
$Script:ActivityLog = "$Script:LogsDir\tweak_activity.log"
if (!(Test-Path $Script:LogsDir)) { New-Item -ItemType Directory -Path $Script:LogsDir -Force | Out-Null }

function Log-Activity { param([string]$Message); "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" | Out-File -FilePath $Script:ActivityLog -Append -Encoding UTF8 }

Clear-Host
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "  THERMAL CHECK - Temperature Monitoring" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""

# Get thermal information from WMI
Write-Host "  Reading thermal zones..." -ForegroundColor Cyan
Write-Host ""

try {
    $ThermalZones = Get-WmiObject -Namespace "root\wmi" -Class "MSAcpi_ThermalZoneTemperature" -ErrorAction Stop
    foreach ($Zone in $ThermalZones) {
        $TempK = $Zone.CurrentTemperature
        if ($TempK -gt 0) {
            $TempC = [math]::Round(($TempK - 2732) / 10, 1)
            $TempF = [math]::Round(($TempC * 9/5) + 32, 1)
            $Status = "Normal"
            if ($TempC -gt 70) { $Status = "HOT"; $Color = "Yellow" }
            if ($TempC -gt 85) { $Status = "CRITICAL"; $Color = "Red" }
            
            Write-Host "  Zone: $($Zone.Name)" -ForegroundColor White
            Write-Host "    Temperature: $TempC°C ($TempF°F) - $Status" -ForegroundColor $Color
            Write-Host ""
        }
    }
} catch {
    Write-Host "  [INFO] Thermal data not available via WMI." -ForegroundColor Yellow
    Write-Host "  [INFO] This is normal for some systems." -ForegroundColor Yellow
}

# CPU temperature estimate from clock throttling
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host " [CPU Status]" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor DarkGray

$CPU = Get-CimInstance Win32_Processor
$CurrentClock = $CPU.CurrentClockSpeed | Measure-Object -Average | Select-Object -ExpandProperty Average
$MaxClock = $CPU.MaxClockSpeed
if ($MaxClock -gt 0) {
    $Utilization = [math]::Round(($CurrentClock / $MaxClock) * 100, 0)
    Write-Host "  Current Clock: $CurrentClock MHz / $MaxClock MHz" -ForegroundColor White
    Write-Host "  Utilization: $Utilization%" -ForegroundColor White
    if ($Utilization -lt 30) {
        Write-Host "  Status: Cool - CPU is not throttling" -ForegroundColor Green
    } else {
        Write-Host "  Status: Normal operation" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "  Thermal check complete!" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""

Log-Activity "THERMAL_CHECK: Thermal monitoring completed"

Write-Host "  Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
