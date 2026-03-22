<#
.SYNOPSIS
    GandiWin System Check - Hardware/Software Intelligence Terminal
.DESCRIPTION
    Comprehensive system information display with hacker-style terminal UI
    Target: Windows 10/11 with PowerShell 3.0+
#>

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

Set-GandiConsole -Title "GANDIWIN :: SYSTEM CHECK"

# ============================================================================
# GATHER SYSTEM INFORMATION
# ============================================================================

Show-GandiBanner
Invoke-GandiTypewriter -Text "INITIALIZING SYSTEM SCAN SEQUENCE..." -DelayMs 10 -Color Green
Start-Sleep -Milliseconds 500

# OS Information
Write-GandiStatus -Status "WAIT" -Message "Gathering OS information..."
$OS = Get-CimInstance Win32_OperatingSystem
$OSName = $OS.Caption
$OSBuild = $OS.BuildNumber
$OSSKU = $OS.OperatingSystemSKU
$OSArch = (Get-CimInstance Win32_Processor).AddressWidth | Select-Object -First 1

# Determine OS Edition
$OSEdition = "Unknown"
switch ($OSSKU) {
    1 { $OSEdition = "Ultimate" }
    4 { $OSEdition = "Enterprise" }
    48 { $OSEdition = "Professional" }
    49 { $OSEdition = "Professional N" }
    65 { $OSEdition = "Home" }
    66 { $OSEdition = "Home N" }
    101 { $OSEdition = "Home Single Language" }
    default { $OSEdition = "Professional" }
}

# OS Release
$OSRelease = "Unknown"
if ([int]$OSBuild -ge 22000) { $OSRelease = "23H2" }
elseif ([int]$OSBuild -ge 19045) { $OSRelease = "22H2" }
elseif ([int]$OSBuild -ge 19044) { $OSRelease = "21H2" }

# Boot Mode
$BootMode = "Legacy"
$SecureBoot = "Unknown"
$HVCI = "Unknown"

try {
    $RegValue = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "PEFirmwareType" -ErrorAction SilentlyContinue
    if ($RegValue.PEFirmwareType -eq 2) { $BootMode = "UEFI" }
}
catch {}

try {
    $SB = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State" -Name "UEFISecureBootEnabled" -ErrorAction SilentlyContinue
    if ($SB.UEFISecureBootEnabled -eq 1) { $SecureBoot = "ON" } else { $SecureBoot = "OFF" }
}
catch { $SecureBoot = "OFF" }

try {
    $HVCIVal = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -ErrorAction SilentlyContinue
    if ($HVCIVal.Enabled -eq 1) { $HVCI = "ON" } else { $HVCI = "OFF" }
}
catch { $HVCI = "OFF" }

# Computer Info
Write-GandiStatus -Status "WAIT" -Message "Gathering computer information..."
$Computer = Get-CimInstance Win32_ComputerSystem
$CompName = $Computer.Name
$CompModel = $Computer.Model
$CompManufacturer = $Computer.Manufacturer

# Motherboard Info
Write-GandiStatus -Status "WAIT" -Message "Gathering motherboard information..."
$BaseBoard = Get-CimInstance Win32_BaseBoard
$MBManufacturer = $BaseBoard.Manufacturer
$MBModel = $BaseBoard.Product
$BIOS = Get-CimInstance Win32_BIOS
$BIOSVersion = $BIOS.SMBIOSBIOSVersion
$BIOSDate = $BIOS.ReleaseDate.ToString("yyyy-MM-dd")

# TPM Info
$TPMStatus = "Not Detected"
try {
    $TPM = Get-CimInstance -Namespace "root\cimv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue
    if ($TPM -and $TPM.IsEnabled) { $TPMStatus = "Detected (Enabled)" }
}
catch {}

# CPU Info
Write-GandiStatus -Status "WAIT" -Message "Gathering processor information..."
$CPU = Get-CimInstance Win32_Processor
$CPUName = $CPU.Name
$CPUVendor = "Unknown"
if ($CPUName -like "*Intel*") { $CPUVendor = "Intel" }
if ($CPUName -like "*AMD*") { $CPUVendor = "AMD" }
$CPUCores = $CPU.NumberOfCores
$CPUThreads = $CPU.NumberOfLogicalProcessors
$CPUMaxClock = $CPU.MaxClockSpeed
$CPUCurrentClock = (Get-CimInstance Win32_Processor).CurrentClockSpeed | Select-Object -First 1

# RAM Info
Write-GandiStatus -Status "WAIT" -Message "Gathering memory information..."
$RAMTotal = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
$RAMModules = Get-CimInstance Win32_PhysicalMemory
$RAMModuleCount = ($RAMModules | Measure-Object).Count
$RAMSpeed = "Unknown"
if ($RAMModules) {
    $RAMSpeed = "$($RAMModules[0].Speed) MHz"
}

# GPU Info
Write-GandiStatus -Status "WAIT" -Message "Gathering graphics information..."
$GPU = Get-CimInstance Win32_VideoController
$GPUName = $GPU.Name
$GPUDriver = $GPU.DriverVersion
$GPUType = "Integrated"
if ($GPUName -like "*RTX*" -or $GPUName -like "*GTX*" -or $GPUName -like "*RX *" -or $GPUName -like "*Vega*") {
    $GPUType = "Discrete"
}
$GPUMem = [math]::Round($GPU.AdapterRAM / 1MB, 0)

# Storage Info
Write-GandiStatus -Status "WAIT" -Message "Gathering storage information..."
$Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

# Network Info
Write-GandiStatus -Status "WAIT" -Message "Gathering network information..."
$NetworkAdapters = Get-CimInstance Win32_NetworkAdapter -Filter "NetEnabled=true"
$DNS = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses } | Select-Object -First 1
$DNSServers = "Unknown"
if ($DNS) { $DNSServers = ($DNS.ServerAddresses -join ", ") }

# ============================================================================
# DISPLAY ALL INFORMATION
# ============================================================================

Clear-Host
Show-GandiBanner
Invoke-GandiTypewriter -Text "SYSTEM INTELLIGENCE REPORT [TIMESTAMP $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]" -DelayMs 5 -Color White

Show-GandiBox -Title "OVERVIEW"
Show-GandiKeyValue "Computer Name" $CompName
Show-GandiKeyValue "Manufacturer" $CompManufacturer
Show-GandiKeyValue "Model" $CompModel

Show-GandiBox -Title "MOTHERBOARD"
Show-GandiKeyValue "Manufacturer" $MBManufacturer
Show-GandiKeyValue "Model" $MBModel
Show-GandiKeyValue "BIOS Date" $BIOSDate
Show-GandiKeyValue "BIOS Version" $BIOSVersion
Show-GandiKeyValue "Boot Type" $BootMode
Show-GandiKeyValue "TPM Chip" $TPMStatus

Show-GandiBox -Title "OPERATING SYSTEM"
Show-GandiKeyValue "OS" "Microsoft Windows $OSEdition ($OSArch-bit) Build $OSBuild ($OSRelease)"
Show-GandiKeyValue "Boot Mode" $BootMode
Show-GandiKeyValue "Secure Boot" $SecureBoot
Show-GandiKeyValue "HVCI" $HVCI

Show-GandiBox -Title "PROCESSOR" -Color "Yellow"
Show-GandiKeyValue "Model" $CPUName "White" "Yellow"
Show-GandiKeyValue "Vendor" $CPUVendor "White" "Yellow"
Show-GandiKeyValue "Cores / Threads" "$CPUCores / $CPUThreads" "White" "Yellow"
Show-GandiKeyValue "Max Clock" "$CPUMaxClock MHz" "White" "Yellow"
Show-GandiKeyValue "Current Clock" "$CPUCurrentClock MHz" "White" "Yellow"
Show-GandiKeyValue "TDP" "N/A" "White" "Yellow"

Show-GandiBox -Title "RAM INFO" -Color "Green"
Show-GandiKeyValue "Total Capacity" "$RAMTotal GB" "White" "Green"
Show-GandiKeyValue "Speed" $RAMSpeed "White" "Green"
Show-GandiKeyValue "Modules" "$RAMModuleCount" "White" "Green"

Show-GandiBox -Title "GRAPHICS" -Color "Magenta"
Show-GandiKeyValue "Model" $GPUName "White" "Magenta"
Show-GandiKeyValue "Driver Version" $GPUDriver "White" "Magenta"
Show-GandiKeyValue "Type" $GPUType "White" "Magenta"
Show-GandiKeyValue "Memory" "$GPUMem MB" "White" "Magenta"

Show-GandiBox -Title "STORAGE"
foreach ($Disk in $Disks) {
    $FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
    $TotalGB = [math]::Round($Disk.Size / 1GB, 2)
    $Percent = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 0)
    Show-GandiKeyValue "Drive $($Disk.DeviceID)" "$FreeGB GB free of $TotalGB GB ($Percent%)"
}

Show-GandiBox -Title "NETWORK"
if ($NetworkAdapters) {
    foreach ($Adapter in $NetworkAdapters) {
        Show-GandiKeyValue "Adapter" $Adapter.Name
    }
}
Show-GandiKeyValue "DNS Servers" $DNSServers

# ============================================================================
# MENU OPTIONS
# ============================================================================

Write-Host ""
Write-Host "  ================================================================" -ForegroundColor DarkCyan
Write-Host "  [R] REFRESH SCAN     [S] SAVE REPORT     [Q] DEACTIVATE TERMINAL" -ForegroundColor Yellow
Write-Host "  ================================================================" -ForegroundColor DarkCyan
Write-Host ""

$InputCmd = Read-Host "  AWAITING COMMAND"

switch ($InputCmd.ToUpper()) {
    "R" { & $PSCommandPath }
    "S" {
        $LogFile = "$PSScriptRoot\logs\system_check_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        if (!(Test-Path "$PSScriptRoot\logs")) { New-Item -ItemType Directory -Path "$PSScriptRoot\logs" | Out-Null }
        
        @"
================================================================================
GANDIWIN SYSTEM CHECK REPORT
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================

[OVERVIEW]
Computer Name: $CompName
Manufacturer: $CompManufacturer
Model: $CompModel

[MOTHERBOARD]
Manufacturer: $MBManufacturer
Model: $MBModel
BIOS Date: $BIOSDate
BIOS Version: $BIOSVersion
Boot Type: $BootMode
TPM: $TPMStatus

[OPERATING SYSTEM]
OS: Microsoft Windows $OSEdition ($OSArch-bit) Build $OSBuild ($OSRelease)
Boot Mode: $BootMode
Secure Boot: $SecureBoot
HVCI: $HVCI

[PROCESSOR]
Model: $CPUName
Vendor: $CPUVendor
Cores/Threads: $CPUCores/$CPUThreads
Max Clock: $CPUMaxClock MHz

[RAM]
Total: $RAMTotal GB
Speed: $RAMSpeed
Modules: $RAMModuleCount

[GRAPHICS]
Model: $GPUName
Driver: $GPUDriver
Type: $GPUType
Memory: $GPUMem MB

[STORAGE]
$(foreach ($Disk in $Disks) {
    $FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
    $TotalGB = [math]::Round($Disk.Size / 1GB, 2)
    $Percent = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 0)
    "Drive $($Disk.DeviceID): $FreeGB GB free of $TotalGB GB ($Percent%)"
})
================================================================================
"@ | Out-File -FilePath $LogFile -Encoding UTF8
        
        Write-GandiStatus -Status "OK" -Message "Report successfully archived to: $LogFile"
        Start-Sleep -Seconds 2
    }
    "Q" { 
        Invoke-GandiTypewriter -Text "TERMINATING CONNECTION..." -DelayMs 10 -Color Red
        pause
        exit
    }
    default { Write-GandiStatus -Status "FAIL" -Message "INVALID COMMAND SEQUENCE."; Start-Sleep -Seconds 1 }
}
