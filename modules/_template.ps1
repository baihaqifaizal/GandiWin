<#
.SYNOPSIS
    GandiWin Module Template
.DESCRIPTION
    Template for all 30 optimization modules
#>

[Console]::Title = "GANDIWIN :: MODULE_NAME"
[Console]::BackgroundColor = "Black"
[Console]::ForegroundColor = "Green"
Clear-Host

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:LogsDir = "$PSScriptRoot\..\logs"
$Script:ActivityLog = "$Script:LogsDir\tweak_activity.log"

# Create logs directory
if (!(Test-Path $Script:LogsDir)) { New-Item -ItemType Directory -Path $Script:LogsDir -Force | Out-Null }

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Show-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host "  $Title" -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host ""
}

function Show-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host " [$Text]" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}

function Log-Activity {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] $Message" | Out-File -FilePath $Script:ActivityLog -Append -Encoding UTF8
}

function Show-Success {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Show-Error {
    param([string]$Message)
    Write-Host "  [X] ERROR: $Message" -ForegroundColor Red
}

function Show-Warning {
    param([string]$Message)
    Write-Host "  [!] WARNING: $Message" -ForegroundColor Yellow
}

function Show-Info {
    param([string]$Message)
    Write-Host "  [*] $Message" -ForegroundColor Cyan
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

Show-Header "MODULE_NAME - DESCRIPTION"

# Add your module logic here

Show-Info "Module is running..."

# Example: Log activity
Log-Activity "MODULE_NAME: Executed"

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "  Module complete!" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
