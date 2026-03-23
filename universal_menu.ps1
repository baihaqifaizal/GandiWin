# GandiWin Universal Menu
# WAJIB ada di setiap script utama (Rule 1.4)
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    pause
    exit 1
}

# Import The UI Module
$UIModule = "$PSScriptRoot\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

Set-GandiConsole -Title "GANDIWIN :: CONTROL CENTER"

$ModulesDir = "$PSScriptRoot\modules"
$LogsDir = "$PSScriptRoot\logs"
$FeaturesDir = "$PSScriptRoot\features"
$ActivityLog = "$LogsDir\menu.log"

if (!(Test-Path $ModulesDir)) { New-Item -ItemType Directory -Path $ModulesDir -Force | Out-Null }
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (!(Test-Path $FeaturesDir)) { New-Item -ItemType Directory -Path $FeaturesDir -Force | Out-Null }

function Log-Activity {
    param($Message)
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" | Out-File -FilePath $ActivityLog -Append -Encoding UTF8
}

$Features = @(
    @{Num = 1; Name = "Thermal Check" },
    @{Num = 2; Name = "Antivirus Conflict" },
    @{Num = 3; Name = "Bloatware Removal" },
    @{Num = 4; Name = "Startup Control" },
    @{Num = 5; Name = "Background Services" },
    @{Num = 6; Name = "Background Apps" },
    @{Num = 7; Name = "Telemetry Disabler" },
    @{Num = 8; Name = "Delivery Optimization" },
    @{Num = 9; Name = "Scheduled Tasks" },
    @{Num = 10; Name = "Disk Cleanup" },
    @{Num = 11; Name = "NTFS Repair" },
    @{Num = 12; Name = "AppData Cleanup" },
    @{Num = 13; Name = "Ghost Drivers" },
    @{Num = 14; Name = "Hibernation Disable" },
    @{Num = 15; Name = "Virtual Memory" },
    @{Num = 16; Name = "Spectre Meltdown" },
    @{Num = 17; Name = "CPU Core Unparking" },
    @{Num = 18; Name = "MSI Mode Interrupt" },
    @{Num = 19; Name = "Network Throttling" },
    @{Num = 20; Name = "GPU HAGS" },
    @{Num = 21; Name = "Nagle Algorithm" },
    @{Num = 22; Name = "Visual Effects" },
    @{Num = 23; Name = "Power Plan" },
    @{Num = 24; Name = "USB Selective Suspend" },
    @{Num = 25; Name = "Mouse Precision" },
    @{Num = 26; Name = "Shell Extensions" },
    @{Num = 27; Name = "Explorer Quick Access" },
    @{Num = 28; Name = "Indexing Service" },
    @{Num = 29; Name = "Registry Optimization" },
    @{Num = 30; Name = "Game Mode Bar" }
)

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: CONTROL CENTER"
    Show-GandiBanner

    Show-GandiBox -Title "FEATURES DIRECTORY"
    Write-Host ""

    for ($i = 0; $i -lt 30; $i += 2) {
        $Num1 = $Features[$i].Num.ToString("00")
        $Name1 = $Features[$i].Name.PadRight(25)
        
        Write-Host "  [" -NoNewline -ForegroundColor DarkGray
        Write-Host $Num1 -NoNewline -ForegroundColor Yellow
        Write-Host "] " -NoNewline -ForegroundColor DarkGray
        Write-Host $Name1 -NoNewline -ForegroundColor Cyan
        
        if ($i + 1 -lt 30) {
            $Num2 = $Features[$i + 1].Num.ToString("00")
            $Name2 = $Features[$i + 1].Name
            
            Write-Host "  [" -NoNewline -ForegroundColor DarkGray
            Write-Host $Num2 -NoNewline -ForegroundColor Yellow
            Write-Host "] " -NoNewline -ForegroundColor DarkGray
            Write-Host $Name2 -ForegroundColor Cyan
        }
        else {
            Write-Host ""
        }
    }

    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host "  [A] RUN ALL SAFE      [R] REFRESH SYSTEM      [Q] DEACTIVATE" -ForegroundColor Yellow
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""

    $Choice = Read-Host "  AWAITING COMMAND (1-30)"

    if ($Choice -eq "Q") { 
        Invoke-GandiTypewriter -Text "SHUTTING DOWN TERMINAL..." -DelayMs 10 -Color Red
        pause; exit 
    }
    if ($Choice -eq "R") { continue }
    if ($Choice -eq "A") {
        Write-GandiStatus -Status "WARN" -Message "Batch mode explicitly locked. Coming soon."
        Start-Sleep -Seconds 1
        continue
    }

    if ($Choice -match "^\d+$") {
        $Num = [int]$Choice
        if ($Num -ge 1 -and $Num -le 30) {
            $Feature = $Features | Where-Object { $_.Num -eq $Num }
            $FolderName = "$Num`_$($Feature.Name.ToLower().Replace(' ','_'))"
            $ScriptPath = Join-Path $FeaturesDir "$FolderName\$FolderName.ps1"
            Log-Activity "TWEAK INITIATED: #$Num - $($Feature.Name)"
        
            if (Test-Path $ScriptPath) {
                Write-GandiStatus -Status "OK" -Message "Executing module $FolderName"
                Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`""
            }
            else {
                Write-GandiStatus -Status "FAIL" -Message "Module script missing: $ScriptPath"
                Start-Sleep -Seconds 2
            }
        }
    }

}
