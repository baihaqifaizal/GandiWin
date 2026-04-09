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

# Init log (ATURAN Layer 1)
if ($PSScriptRoot -ne '') { $ScriptDir = $PSScriptRoot }
else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
$LogFile = "$ScriptDir\logs\menu.log"
if (!(Test-Path "$ScriptDir\logs")) { New-Item -ItemType Directory -Path "$ScriptDir\logs" -Force | Out-Null }
function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [SYSTEM_CHECK] $Message" -ErrorAction SilentlyContinue } catch {}
}

Set-GandiConsole -Title "GANDIWIN :: SYSTEM CHECK"
Write-ActivityLog "System Check launched"
# ============================================================================
# GATHER SYSTEM INFORMATION
# ============================================================================

Show-GandiBanner
Invoke-GandiTypewriter -Text "INITIALIZING SYSTEM SCAN SEQUENCE..." -DelayMs 10 -Color Green
Start-Sleep -Milliseconds 500

# OS Information
Write-GandiStatus -Status "WAIT" -Message "Gathering OS information..."
$OS = Get-CimInstance Win32_OperatingSystem
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

# Base Clock = CurrentClockSpeed (base speed Windows reports, e.g., 1.9 GHz)
$CPUBaseClock = $CPU.CurrentClockSpeed

# Real-time CPU frequency using % Processor Performance counter
# This shows actual scaling under load (turbo boost 3.2-3.6 GHz)
$CPURealTimeFreq = 0
try {
    $PerfCounter = (Get-Counter "\Processor Information(_Total)\%% Processor Performance" -ErrorAction Stop).CounterSamples.CookedValue
    # PerfCounter is percentage (e.g., 200 = 200% of base = 1.9 * 2.0 = 3.8 GHz)
    if ($PerfCounter -gt 0 -and $CPUBaseClock -gt 0) {
        $CPURealTimeFreq = [math]::Round($CPUBaseClock * ($PerfCounter / 100), 0)
    }
}
catch {}

if ($CPURealTimeFreq -eq 0) {
    $CPURealTimeFreq = $CPUBaseClock
}

# Base Clock vs Max Hardware Speed
$CPUBaseGHz = [math]::Round($CPUBaseClock / 1000, 2)
$CPUTurboMax = [math]::Round($CPU.MaxClockSpeed / 1000, 1)  # Max hardware capability (Turbo)
$CPURealTimeGHz = [math]::Round($CPURealTimeFreq / 1000, 1)

# Note: Win32_Processor.MaxClockSpeed reports the MAXIMUM rated speed (turbo)
# If it equals CurrentClockSpeed, the CPU doesn't have turbo or it's not reported

# Turbo Boost Detection
$CPUTurbo = "N/A"
$BoostModeAC = "Unknown"
$BoostModeDC = "Unknown"
try {
    # Check if real-time frequency exceeds base (means turbo is active)
    if ($CPURealTimeFreq -gt 0 -and $CPUTurboMax -gt 0) {
        $RealGHz = [math]::Round($CPURealTimeFreq / 1000, 1)
        $TurboGHz = [math]::Round($CPU.MaxClockSpeed / 1000, 1)
        if ($RealGHz -ge $TurboGHz) {
            $CPUTurbo = "$TurboGHz GHz (At Max)"
        } elseif ($RealGHz -gt $CPUBaseGHz) {
            $CPUTurbo = "$TurboGHz GHz (Active: ${RealGHz} GHz)"
        } else {
            $CPUTurbo = "$TurboGHz GHz (Available)"
        }
    }
    
    # Detect Boost Mode from Power Plan settings using GUID query
    $activePlan = (powercfg /getactivescheme) -split '\s+' | Where-Object { $_ -match '^[0-9a-f-]{36}$' }
    if (-not $activePlan) {
        # Fallback: extract GUID from powercfg output
        $activePlan = (powercfg /getactivescheme) | ForEach-Object { if ($_ -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') { $matches[1] } } | Select-Object -First 1
    }
    
    if ($activePlan) {
        # Processor Performance Boost Policy GUIDs
        $subGroup = "54533251-82be-4824-96c1-47b60b740d00"  # SUB_PROCESSOR
        $boostPolicy = "be337238-0d82-4146-a960-4f3749d470c7"  # PROCPERFINCREASEPOLICY
        
        $boostQuery = powercfg /query $activePlan $subGroup $boostPolicy 2>$null
        
        # Parse AC Setting
        $acLine = $boostQuery | Select-String "Current AC Power Setting Index"
        if ($acLine) {
            $acVal = ($acLine.ToString() -split '\s+')[-1]
            switch ($acVal) {
                "0x00000000" { $BoostModeAC = "Disabled" }
                "0x00000001" { $BoostModeAC = "Enabled" }
                "0x00000002" { $BoostModeAC = "Aggressive" }
                default { $BoostModeAC = "Custom ($acVal)" }
            }
        }
        
        # Parse DC Setting
        $dcLine = $boostQuery | Select-String "Current DC Power Setting Index"
        if ($dcLine) {
            $dcVal = ($dcLine.ToString() -split '\s+')[-1]
            switch ($dcVal) {
                "0x00000000" { $BoostModeDC = "Disabled" }
                "0x00000001" { $BoostModeDC = "Enabled" }
                "0x00000002" { $BoostModeDC = "Aggressive" }
                default { $BoostModeDC = "Custom ($dcVal)" }
            }
        }
    }
}
catch {}

# RAM Info
Write-GandiStatus -Status "WAIT" -Message "Gathering memory information..."
$RAMTotal = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
$RAMFree = [math]::Round($OS.FreePhysicalMemory / 1MB, 2)
$RAMUsed = [math]::Round($RAMTotal - $RAMFree, 2)
$RAMUsageRate = [math]::Round(($RAMUsed / $RAMTotal) * 100, 2)
$RAMModules = Get-CimInstance Win32_PhysicalMemory
$RAMModuleCount = ($RAMModules | Measure-Object).Count
$RAMSpeed = "Unknown"
if ($RAMModules) {
    $RAMSpeed = "$($RAMModules[0].Speed) MHz"
}

# Detailed Memory Counters
Write-GandiStatus -Status "WAIT" -Message "Gathering detailed memory statistics..."
$MemCounters = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction SilentlyContinue
$RAMInUseCompressed = "N/A"
$RAMAvailableCommitted = "N/A"
$RAMCached = "N/A"
$RAMPagedPool = "N/A"
$RAMNonPagedPool = "N/A"
if ($MemCounters) {
    # In Use (Compressed) - bytes of compressed memory in use
    if ($MemCounters.CommittedBytes -gt 0) {
        $RAMInUseCompressed = "$([math]::Round($MemCounters.CommittedBytes / 1MB, 2)) MB"
    }
    # Available Committed - KB of memory that can be committed without paging
    if ($MemCounters.AvailableBytes -gt 0) {
        $RAMAvailableCommitted = "$([math]::Round($MemCounters.AvailableBytes / 1MB, 2)) MB"
    }
    # Cached - bytes of cached memory
    if ($MemCounters.CacheBytes -gt 0) {
        $RAMCached = "$([math]::Round($MemCounters.CacheBytes / 1MB, 2)) MB"
    }
    # Paged Pool - bytes of paged pool memory
    if ($MemCounters.PoolPagedBytes -gt 0) {
        $RAMPagedPool = "$([math]::Round($MemCounters.PoolPagedBytes / 1MB, 2)) MB"
    }
    # Non-Paged Pool - bytes of non-paged pool memory
    if ($MemCounters.PoolNonPagedBytes -gt 0) {
        $RAMNonPagedPool = "$([math]::Round($MemCounters.PoolNonPagedBytes / 1MB, 2)) MB"
    }
}

# Hardware Logs (Event Viewer)
Write-GandiStatus -Status "WAIT" -Message "Checking hardware logs..."
$MemLogs = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue | Where-Object {$_.Message -match "Memory"}
$HWStatus = if ($MemLogs) { "Events Detected" } else { "No Errors Detected" }

# Virtual Memory & Page File
Write-GandiStatus -Status "WAIT" -Message "Gathering virtual memory information..."
$VirtualMemTotal = [math]::Round($OS.TotalVirtualMemorySize / 1MB, 2)
$VirtualMemUsed = [math]::Round(($OS.TotalVirtualMemorySize - $OS.FreeVirtualMemory) / 1MB, 2)
$PageFiles = Get-CimInstance Win32_PageFileUsage | Select-Object Name, CurrentUsage, AllocatedBaseSize

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

# Display Info
$DisplayRes = "N/A"
$DisplayRefresh = "N/A"
try {
    if ($GPU.CurrentHorizontalResolution -and $GPU.CurrentVerticalResolution) {
        $DisplayRes = "$($GPU.CurrentHorizontalResolution) x $($GPU.CurrentVerticalResolution)"
    }
    if ($GPU.CurrentRefreshRate) {
        $DisplayRefresh = "$($GPU.CurrentRefreshRate) Hz"
    }
}
catch {}

# Storage Info
Write-GandiStatus -Status "WAIT" -Message "Gathering storage information..."
$Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

# Storage Health & Type (SMART data)
$DiskHealth = "Unknown"
$DiskType = "Unknown"
try {
    $PhysicalDisk = Get-PhysicalDisk | Select-Object -First 1
    if ($PhysicalDisk) {
        $DiskHealth = $PhysicalDisk.HealthStatus
        $DiskType = if ($PhysicalDisk.MediaType) { $PhysicalDisk.MediaType } else { "SSD" }
    }
}
catch {}

# Storage Performance Counters
Write-GandiStatus -Status "WAIT" -Message "Gathering storage performance statistics..."
$StorageReadSpeed = "N/A"
$StorageWriteSpeed = "N/A"
$StorageResponseTime = "N/A"
try {
    $DiskPerf = Get-Counter "\PhysicalDisk(_Total)\Disk Read Bytes/sec", "\PhysicalDisk(_Total)\Disk Write Bytes/sec", "\PhysicalDisk(_Total)\Avg. Disk sec/Transfer" -ErrorAction SilentlyContinue
    if ($DiskPerf -and $DiskPerf.CounterSamples) {
        $ReadBytes = ($DiskPerf.CounterSamples | Where-Object { $_.Path -like "*Read Bytes*" }).CookedValue
        $WriteBytes = ($DiskPerf.CounterSamples | Where-Object { $_.Path -like "*Write Bytes*" }).CookedValue
        $AvgSecTransfer = ($DiskPerf.CounterSamples | Where-Object { $_.Path -like "*Avg. Disk sec*" }).CookedValue
        
        if ($ReadBytes -gt 0) {
            if ($ReadBytes -gt 1GB) {
                $StorageReadSpeed = "$([math]::Round($ReadBytes / 1GB, 2)) GB/s"
            } else {
                $StorageReadSpeed = "$([math]::Round($ReadBytes / 1MB, 2)) MB/s"
            }
        }
        if ($WriteBytes -gt 0) {
            if ($WriteBytes -gt 1GB) {
                $StorageWriteSpeed = "$([math]::Round($WriteBytes / 1GB, 2)) GB/s"
            } else {
                $StorageWriteSpeed = "$([math]::Round($WriteBytes / 1MB, 2)) MB/s"
            }
        }
        if ($AvgSecTransfer -gt 0) {
            $StorageResponseTime = "$([math]::Round($AvgSecTransfer * 1000, 2)) ms"
        }
    }
}
catch {}

# Network Info
Write-GandiStatus -Status "WAIT" -Message "Gathering network information..."
$NetworkAdapters = Get-CimInstance Win32_NetworkAdapter -Filter "NetEnabled=true"
$DNS = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses } | Select-Object -First 1
$DNSServers = "Unknown"
if ($DNS) { $DNSServers = ($DNS.ServerAddresses -join ", ") }

# Battery Info
Write-GandiStatus -Status "WAIT" -Message "Gathering battery information..."
$Battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
$BatteryCharge = "N/A"
$BatteryStatus = "N/A"
$BatteryWearLevel = "N/A"
if ($Battery) {
    $BatteryCharge = "$($Battery.EstimatedChargeRemaining)%"
    $BatteryStatus = switch ($Battery.BatteryStatus) {
        1 { "Discharging" }
        2 { "On AC Power" }
        3 { "Fully Charged" }
        4 { "Low" }
        5 { "Critical" }
        default { "Unknown ($($Battery.BatteryStatus))" }
    }
    
    # Battery Wear Level
    try {
        $BattInfo = Get-CimInstance -Namespace root/WMI -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue
        $BattDesign = Get-CimInstance -Namespace root/WMI -ClassName BatteryStaticData -ErrorAction SilentlyContinue
        if ($BattInfo -and $BattDesign) {
            # Handle array results (some laptops have multiple batteries)
            $FullCap = 0
            $DesignCap = 0
            if ($BattInfo -is [Array]) {
                $FullCap = ($BattInfo | Measure-Object -Property FullChargedCapacity -Sum).Sum
            } else {
                $FullCap = $BattInfo.FullChargedCapacity
            }
            if ($BattDesign -is [Array]) {
                $DesignCap = ($BattDesign | Measure-Object -Property DesignedCapacity -Sum).Sum
            } else {
                $DesignCap = $BattDesign.DesignedCapacity
            }
            if ($DesignCap -gt 0 -and $FullCap -gt 0) {
                $WearPercent = [math]::Round(($FullCap / $DesignCap) * 100, 1)
                $BatteryWearLevel = "$WearPercent%"
            }
        }
    }
    catch {}
    
    # Fallback: Try Win32_PortableBattery (works better on Legacy Boot)
    if ($BatteryWearLevel -eq "N/A") {
        try {
            $PortBatt = Get-CimInstance Win32_PortableBattery -ErrorAction SilentlyContinue
            if ($PortBatt) {
                $PortFullCap = 0
                $PortDesignCap = 0
                if ($PortBatt -is [Array]) {
                    $PortFullCap = ($PortBatt | Measure-Object -Property FullChargeCapacity -Sum).Sum
                    $PortDesignCap = ($PortBatt | Measure-Object -Property DesignCapacity -Sum).Sum
                } else {
                    $PortFullCap = $PortBatt.FullChargeCapacity
                    $PortDesignCap = $PortBatt.DesignCapacity
                }
                if ($PortDesignCap -gt 0 -and $PortFullCap -gt 0) {
                    $WearPercent = [math]::Round(($PortFullCap / $PortDesignCap) * 100, 1)
                    $BatteryWearLevel = "$WearPercent%"
                }
            }
        }
        catch {}
    }
}

# Thermal Info
Write-GandiStatus -Status "WAIT" -Message "Gathering thermal information..."
$ThermalTemp = "N/A"
$ThermalProfile = "N/A"
$ThermalSafeLimit = "N/A"
$ThermalStatus = "N/A"
$ThermalNote = "N/A"
try {
    $Thermal = Get-CimInstance -Namespace "root\wmi" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    if ($Thermal) {
        $ThermalRaw = [math]::Round(($Thermal.CurrentTemperature / 10) - 273.15, 1)
        $ThermalTemp = "$ThermalRaw C"

        # CPU Profile Detection
        $cpuName = (Get-CimInstance Win32_Processor).Name

        # Low Power / Ultrabook
        if ($cpuName -match "\d{3,5}U|\d{3,5}Y|\d{4}G[1-7]|Athlon|Pentium|Celeron") {
            $ThermalProfile = "Low Power (Ultrabook/Office)"
            $ThermalSafeLimit = "85.0 C"
            if ($ThermalRaw -lt 45) { $ThermalStatus = "SANGAT AMAN"; $ThermalNote = "Suhu sangat baik." }
            elseif ($ThermalRaw -lt 60) { $ThermalStatus = "AMAN"; $ThermalNote = "Suhu wajar untuk kerja ringan." }
            elseif ($ThermalRaw -lt 75) { $ThermalStatus = "NORMAL"; $ThermalNote = "Suhu wajar saat multitasking." }
            elseif ($ThermalRaw -lt 85) { $ThermalStatus = "WASPADA"; $ThermalNote = "Mendekati batas maksimal laptop tipis." }
            else { $ThermalStatus = "KRITIS"; $ThermalNote = "Bahaya Throttling! Cek kipas/pasta termal." }
        }
        # High Performance (Gaming/Creator)
        elseif ($cpuName -match "\d{3,5}H|\d{3,5}HS|\d{3,5}HX|\d{3,5}HK|\d{3,5}XT") {
            $ThermalProfile = "High Performance (Gaming/Creator)"
            $ThermalSafeLimit = "95.0 C"
            if ($ThermalRaw -lt 50) { $ThermalStatus = "SANGAT AMAN"; $ThermalNote = "Sistem pendingin prima." }
            elseif ($ThermalRaw -lt 65) { $ThermalStatus = "AMAN"; $ThermalNote = "Suhu wajar untuk idle/ringan." }
            elseif ($ThermalRaw -lt 85) { $ThermalStatus = "NORMAL"; $ThermalNote = "Suhu optimal saat gaming/rendering." }
            elseif ($ThermalRaw -lt 95) { $ThermalStatus = "WASPADA"; $ThermalNote = "Sistem bekerja ekstra keras." }
            else { $ThermalStatus = "KRITIS"; $ThermalNote = "Overheat! Waktunya repaste / bersihkan debu." }
        }
        # Standard / Desktop PC
        else {
            $ThermalProfile = "Standard/Desktop PC"
            $ThermalSafeLimit = "80.0 C"
            if ($ThermalRaw -lt 45) { $ThermalStatus = "SANGAT AMAN"; $ThermalNote = "Suhu optimal." }
            elseif ($ThermalRaw -lt 60) { $ThermalStatus = "AMAN"; $ThermalNote = "Beban kerja standar." }
            elseif ($ThermalRaw -lt 75) { $ThermalStatus = "NORMAL"; $ThermalNote = "Suhu wajar untuk beban berat." }
            elseif ($ThermalRaw -lt 85) { $ThermalStatus = "WASPADA"; $ThermalNote = "Airflow casing mungkin kurang baik." }
            else { $ThermalStatus = "KRITIS"; $ThermalNote = "Bahaya Overheat! Cek heatsink/AIO." }
        }
    }
}
catch {}

# Power Plan Info
Write-GandiStatus -Status "WAIT" -Message "Gathering power plan information..."
$ActivePlan = "Unknown"
$HealthNote = "N/A"
try {
    $ActivePlan = (Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan -ErrorAction SilentlyContinue | Where-Object IsActive).ElementName
    if (-not $ActivePlan) {
        # Fallback: use powercfg
        $ActivePlan = powercfg /getactivescheme 2>$null | ForEach-Object { if ($_ -match ":\s+(.+)") { $matches[1] } }
    }
    if ($ActivePlan -match "Balanced") {
        $HealthNote = "Optimal for Hardware Longevity."
    } elseif ($ActivePlan -match "High performance") {
        $HealthNote = "High Performance detected. Monitor thermals for longevity."
    } elseif ($ActivePlan -match "Power saver") {
        $HealthNote = "Maximum battery life. Reduced system performance."
    } else {
        $HealthNote = "Custom plan active. Review thermals periodically."
    }
}
catch { $ActivePlan = "N/A" }

# ============================================================================
# DISPLAY ALL INFORMATION
# ============================================================================

Clear-Host
Show-GandiBanner
Invoke-GandiTypewriter -Text "SYSTEM INTELLIGENCE REPORT [TIMESTAMP $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]" -DelayMs 5 -Color White
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "OVERVIEW"
Show-GandiKeyValue "Computer Name" $CompName
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Manufacturer" $CompManufacturer
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Model" $CompModel
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "MOTHERBOARD"
Show-GandiKeyValue "Manufacturer" $MBManufacturer
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Model" $MBModel
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "BIOS Date" $BIOSDate
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "BIOS Version" $BIOSVersion
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Boot Type" $BootMode
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "TPM Chip" $TPMStatus
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "OPERATING SYSTEM"
Show-GandiKeyValue "OS" "Microsoft Windows $OSEdition ($OSArch-bit) Build $OSBuild ($OSRelease)"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Boot Mode" $BootMode
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Secure Boot" $SecureBoot
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "HVCI" $HVCI
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "PROCESSOR" -Color "Yellow"
Show-GandiKeyValue "Model" $CPUName "White" "Yellow"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Vendor" $CPUVendor "White" "Yellow"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Cores / Threads" "$CPUCores / $CPUThreads" "White" "Yellow"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Base Clock" "$CPUBaseGHz GHz" "White" "Yellow"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Max Turbo" $CPUTurbo "White" "Yellow"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Current Clock" "$CPURealTimeGHz GHz (Real-time)" "White" "Yellow"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Boost Mode (AC)" $BoostModeAC "White" "Yellow"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Boost Mode (DC)" $BoostModeDC "White" "Yellow"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "TDP" "N/A" "White" "Yellow"
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "RAM INFO" -Color "Green"
Show-GandiKeyValue "Total RAM" "$RAMTotal GB" "White" "Green"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Used RAM" "$RAMUsed GB" "White" "Green"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Usage Rate" "$RAMUsageRate %" "White" "Green"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Hardware Logs" $HWStatus "White" "Green"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Speed" $RAMSpeed "White" "Green"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Modules" "$RAMModuleCount" "White" "Green"
Start-Sleep -Milliseconds 300
Show-GandiKeyValue "Virtual Memory Total" "$VirtualMemTotal GB" "White" "Green"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Virtual Memory Used" "$VirtualMemUsed GB" "White" "Green"
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "PAGE FILE CONFIGURATION" -Color "Green"
if ($PageFiles) {
    foreach ($pf in $PageFiles) {
        $pfDrive = $pf.Name
        $pfSize = $pf.AllocatedBaseSize
        Show-GandiKeyValue "Page File" "$pfDrive ($pfSize MB)" "White" "Green"
        Start-Sleep -Milliseconds 150
    }
} else {
    Show-GandiKeyValue "Page File" "None / Disabled" "White" "Green"
}
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "GRAPHICS" -Color "Magenta"
Show-GandiKeyValue "Model" $GPUName "White" "Magenta"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Driver Version" $GPUDriver "White" "Magenta"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Type" $GPUType "White" "Magenta"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Memory" "$GPUMem MB" "White" "Magenta"
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "DISPLAY CONFIGURATION" -Color "Magenta"
Show-GandiKeyValue "Resolution" $DisplayRes "White" "Magenta"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Refresh Rate" $DisplayRefresh "White" "Magenta"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "GPU Model" $GPUName "White" "Magenta"
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "STORAGE"
Show-GandiKeyValue "Media Type" $DiskType "White" "Cyan"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Physical Health" "[ $DiskHealth ]" "White" "Cyan"
Start-Sleep -Milliseconds 300
foreach ($Disk in $Disks) {
    $FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
    $TotalGB = [math]::Round($Disk.Size / 1GB, 2)
    $Percent = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 0)
    Show-GandiKeyValue "Drive $($Disk.DeviceID)" "$FreeGB GB free of $TotalGB GB ($Percent%)"
    Start-Sleep -Milliseconds 150
}
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "NETWORK"
if ($NetworkAdapters) {
    foreach ($Adapter in $NetworkAdapters) {
        Show-GandiKeyValue "Adapter" $Adapter.Name
        Start-Sleep -Milliseconds 150
    }
}
Show-GandiKeyValue "DNS Servers" $DNSServers
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "BATTERY STATUS" -Color "Yellow"
Show-GandiKeyValue "Charge" $BatteryCharge "White" "Yellow"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Status" $BatteryStatus "White" "Yellow"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Health / Wear Level" "$BatteryWearLevel (Full Cap vs Design Cap)" "White" "Yellow"
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "THERMAL INFO" -Color "Red"
Show-GandiKeyValue "Current Temp" $ThermalTemp "White" "Red"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "CPU Profile" $ThermalProfile "White" "Red"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Safe Limit" "Up to $ThermalSafeLimit" "White" "Red"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Status" "[ $ThermalStatus ]" "White" "Red"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Recommendation" $ThermalNote "White" "Red"
Start-Sleep -Milliseconds 300

Show-GandiBox -Title "POWER PLAN" -Color "Cyan"
Show-GandiKeyValue "Active Plan" $ActivePlan "White" "Cyan"
Start-Sleep -Milliseconds 150
Show-GandiKeyValue "Health Recommendation" $HealthNote "White" "Cyan"

# ============================================================================
# MENU OPTIONS - BEFORE/AFTER OPTIMIZATION WORKFLOW
# ============================================================================

# Pastikan folder logs dan assets terdeteksi
if (!(Test-Path "$ScriptDir\logs")) { New-Item -ItemType Directory -Path "$ScriptDir\logs" -Force | Out-Null }
$AssetTemplate = "$ScriptDir\assets\template.html"

Write-Host ""
Write-Host "  ==========================================================================" -ForegroundColor DarkCyan
Write-Host "  [B] EXPORT BEFORE LOG   [A] EXPORT AFTER & PRINT REPORT   [Q] DEACTIVATE" -ForegroundColor Yellow
Write-Host "  ==========================================================================" -ForegroundColor DarkCyan
Write-Host ""

$InputCmd = Read-Host "  AWAITING COMMAND"

switch ($InputCmd.ToUpper()) {
    "B" { 
        # ============================================================================
        # LOGIKA BEFORE - Deep Scan dan Save to before.log
        # ============================================================================
        Write-Host ""
        Write-Host "[*] INITIATING BEFORE OPTIMIZATION SCAN..." -ForegroundColor Cyan
        Write-Host "Mengambil data performa sebelum optimasi. Mohon tunggu..." -ForegroundColor Yellow

        $CpuCounterPath = "\Processor(_Total)\% Processor Time"
        $RamCounterPath = "\Memory\Available MBytes"
        $Samples = @()

        # Looping 10 detik dengan Progress Bar
        for ($i = 1; $i -le 10; $i++) {
            Write-Progress -Activity "BEFORE OPTIMIZATION SCAN" -Status "Collecting baseline data... ($i/10 seconds)" -PercentComplete ($i * 10)
            $Sample = Get-Counter -Counter $CpuCounterPath, $RamCounterPath -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
            if ($Sample) { $Samples += $Sample }
        }
        Write-Progress -Activity "BEFORE OPTIMIZATION SCAN" -Completed

        # Kalkulasi hasil rata-rata
        try {
            $CpuValues = $Samples | ForEach-Object { $_.CounterSamples | Where-Object Path -like "*processor*" | Select-Object -ExpandProperty CookedValue }
            $CpuAvgRaw = ($CpuValues | Measure-Object -Average).Average
            $CpuAverage = "$([math]::Round($CpuAvgRaw, 1)) %"

            $RamAvailableValues = $Samples | ForEach-Object { $_.CounterSamples | Where-Object Path -like "*memory*" | Select-Object -ExpandProperty CookedValue }
            $RamAvailableAvgMB = ($RamAvailableValues | Measure-Object -Average).Average
            $TotalRamMB = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB
            $RamUsedAvgMB = $TotalRamMB - $RamAvailableAvgMB
            $RamUsageAvgPercent = [math]::Round(($RamUsedAvgMB / $TotalRamMB) * 100, 1)
            $RamAverage = "$RamUsageAvgPercent %"
        }
        catch {
            $CpuAverage = "N/A"
            $RamAverage = "N/A"
        }

        $TotalProcesses = (Get-Process).Count

        # Collect detailed metrics
        $DeepMemCounters = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction SilentlyContinue
        $DeepRAMInUseCompressed = "N/A"
        $DeepRAMAvailableCommitted = "N/A"
        $DeepRAMCached = "N/A"
        $DeepRAMPagedPool = "N/A"
        $DeepRAMNonPagedPool = "N/A"
        if ($DeepMemCounters) {
            if ($DeepMemCounters.CommittedBytes -gt 0) { $DeepRAMInUseCompressed = "$([math]::Round($DeepMemCounters.CommittedBytes / 1MB, 2)) MB" }
            if ($DeepMemCounters.AvailableBytes -gt 0) { $DeepRAMAvailableCommitted = "$([math]::Round($DeepMemCounters.AvailableBytes / 1MB, 2)) MB" }
            if ($DeepMemCounters.CacheBytes -gt 0) { $DeepRAMCached = "$([math]::Round($DeepMemCounters.CacheBytes / 1MB, 2)) MB" }
            if ($DeepMemCounters.PoolPagedBytes -gt 0) { $DeepRAMPagedPool = "$([math]::Round($DeepMemCounters.PoolPagedBytes / 1MB, 2)) MB" }
            if ($DeepMemCounters.PoolNonPagedBytes -gt 0) { $DeepRAMNonPagedPool = "$([math]::Round($DeepMemCounters.PoolNonPagedBytes / 1MB, 2)) MB" }
        }

        $DeepStorageRead = "N/A"
        $DeepStorageWrite = "N/A"
        $DeepStorageResponse = "N/A"
        try {
            $DeepDiskPerf = Get-Counter "\PhysicalDisk(_Total)\Disk Read Bytes/sec", "\PhysicalDisk(_Total)\Disk Write Bytes/sec", "\PhysicalDisk(_Total)\Avg. Disk sec/Transfer" -ErrorAction SilentlyContinue
            if ($DeepDiskPerf -and $DeepDiskPerf.CounterSamples) {
                $DeepReadBytes = ($DeepDiskPerf.CounterSamples | Where-Object { $_.Path -like "*Read Bytes*" }).CookedValue
                $DeepWriteBytes = ($DeepDiskPerf.CounterSamples | Where-Object { $_.Path -like "*Write Bytes*" }).CookedValue
                $DeepAvgSecTransfer = ($DeepDiskPerf.CounterSamples | Where-Object { $_.Path -like "*Avg. Disk sec*" }).CookedValue

                if ($DeepReadBytes -gt 0) {
                    $DeepStorageRead = if ($DeepReadBytes -gt 1GB) { "$([math]::Round($DeepReadBytes / 1GB, 2)) GB/s" } else { "$([math]::Round($DeepReadBytes / 1MB, 2)) MB/s" }
                }
                if ($DeepWriteBytes -gt 0) {
                    $DeepStorageWrite = if ($DeepWriteBytes -gt 1GB) { "$([math]::Round($DeepWriteBytes / 1GB, 2)) GB/s" } else { "$([math]::Round($DeepWriteBytes / 1MB, 2)) MB/s" }
                }
                if ($DeepAvgSecTransfer -gt 0) { $DeepStorageResponse = "$([math]::Round($DeepAvgSecTransfer * 1000, 2)) ms" }
            }
        }
        catch {}

        # Save BEFORE log
        $LogPath = "$ScriptDir\logs\before.log"
        @"
================================================================================
GANDIWIN SYSTEM CHECK - BEFORE OPTIMIZATION
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
Base Clock: $CPUBaseGHz GHz
Max Turbo: $CPUTurbo
Current Clock: $CPURealTimeGHz GHz (Real-time)
Boost Mode (AC): $BoostModeAC
Boost Mode (DC): $BoostModeDC

[RAM]
Total: $RAMTotal GB
Used: $RAMUsed GB
Usage Rate: $RAMUsageRate %
Hardware Logs: $HWStatus
Speed: $RAMSpeed
Modules: $RAMModuleCount

[GRAPHICS]
Model: $GPUName
Driver: $GPUDriver
Type: $GPUType
Memory: $GPUMem MB

[DISPLAY]
Resolution: $DisplayRes
Refresh Rate: $DisplayRefresh
GPU Model: $GPUName

[STORAGE]
Media Type: $DiskType
Physical Health: $DiskHealth

[NETWORK]
$(if ($NetworkAdapters) { $NetworkAdapters.Name })
DNS Servers: $DNSServers

[BATTERY]
Charge: $BatteryCharge
Status: $BatteryStatus
Health / Wear Level: $BatteryWearLevel (Full Cap vs Design Cap)

[THERMAL]
Current Temp: $ThermalTemp
CPU Profile: $ThermalProfile
Safe Limit: Up to $ThermalSafeLimit
Status: [ $ThermalStatus ]
Recommendation: $ThermalNote

[POWER PLAN]
Active Plan: $ActivePlan
Health Recommendation: $HealthNote

================================================================================

[PERFORMANCE METRICS (BEFORE OPTIMIZATION)]
Average CPU Load     : $CpuAverage
Average RAM Usage    : $RamAverage
Running Processes    : $TotalProcesses background processes

[MEMORY DETAILED (BEFORE OPTIMIZATION)]
Virtual Memory Total: $VirtualMemTotal GB
Virtual Memory Used: $VirtualMemUsed GB
In Use (Compressed): $DeepRAMInUseCompressed
Available Committed: $DeepRAMAvailableCommitted
Cached: $DeepRAMCached
Paged Pool: $DeepRAMPagedPool
Non-Paged Pool: $DeepRAMNonPagedPool

[PAGE FILE]
$(if ($PageFiles) {
    foreach ($pf in $PageFiles) {
        "Page File : $($pf.Name) ($($pf.AllocatedBaseSize) MB)"
    }
} else { "None / Disabled" })

[STORAGE PERFORMANCE (BEFORE OPTIMIZATION)]
Read Speed: $DeepStorageRead
Write Speed: $DeepStorageWrite
Avg Response Time: $DeepStorageResponse
$(foreach ($Disk in $Disks) {
    $FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
    $TotalGB = [math]::Round($Disk.Size / 1GB, 2)
    $Percent = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 0)
    "Drive $($Disk.DeviceID): $FreeGB GB free of $TotalGB GB ($Percent%)"
})
================================================================================
"@ | Out-File -FilePath $LogPath -Encoding UTF8

        Write-ActivityLog "Before log saved: $LogPath" "OK"
        Write-GandiStatus -Status "OK" -Message "BEFORE data secured to logs\before.log"
        Start-Sleep -Seconds 2
    }
    "A" { 
        # ============================================================================
        # LOGIKA AFTER & GENERATE HTML REPORT
        # ============================================================================
        $LogBefore = "$ScriptDir\logs\before.log"
        $LogAfter = "$ScriptDir\logs\after.log"
        
        if (!(Test-Path $LogBefore)) {
            Write-Host ""
            Write-Host "[!] Peringatan: before.log belum ada! Jalankan [B] dulu sebelum [A]." -ForegroundColor Red
            Start-Sleep -Seconds 3
            return
        }

        Write-Host ""
        Write-Host "[*] INITIATING AFTER OPTIMIZATION SCAN..." -ForegroundColor Cyan
        Write-Host "Mengambil data performa setelah optimasi. Mohon tunggu..." -ForegroundColor Yellow

        $CpuCounterPath = "\Processor(_Total)\% Processor Time"
        $RamCounterPath = "\Memory\Available MBytes"
        $Samples = @()

        # Looping 10 detik dengan Progress Bar
        for ($i = 1; $i -le 10; $i++) {
            Write-Progress -Activity "AFTER OPTIMIZATION SCAN" -Status "Collecting post-optimization data... ($i/10 seconds)" -PercentComplete ($i * 10)
            $Sample = Get-Counter -Counter $CpuCounterPath, $RamCounterPath -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
            if ($Sample) { $Samples += $Sample }
        }
        Write-Progress -Activity "AFTER OPTIMIZATION SCAN" -Completed

        # Kalkulasi hasil rata-rata
        try {
            $CpuValues = $Samples | ForEach-Object { $_.CounterSamples | Where-Object Path -like "*processor*" | Select-Object -ExpandProperty CookedValue }
            $CpuAvgRaw = ($CpuValues | Measure-Object -Average).Average
            $CpuAverage = "$([math]::Round($CpuAvgRaw, 1)) %"

            $RamAvailableValues = $Samples | ForEach-Object { $_.CounterSamples | Where-Object Path -like "*memory*" | Select-Object -ExpandProperty CookedValue }
            $RamAvailableAvgMB = ($RamAvailableValues | Measure-Object -Average).Average
            $TotalRamMB = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB
            $RamUsedAvgMB = $TotalRamMB - $RamAvailableAvgMB
            $RamUsageAvgPercent = [math]::Round(($RamUsedAvgMB / $TotalRamMB) * 100, 1)
            $RamAverage = "$RamUsageAvgPercent %"
        }
        catch {
            $CpuAverage = "N/A"
            $RamAverage = "N/A"
        }

        $TotalProcesses = (Get-Process).Count

        # Collect detailed metrics
        $DeepMemCounters = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction SilentlyContinue
        $DeepRAMInUseCompressed = "N/A"
        $DeepRAMAvailableCommitted = "N/A"
        $DeepRAMCached = "N/A"
        $DeepRAMPagedPool = "N/A"
        $DeepRAMNonPagedPool = "N/A"
        if ($DeepMemCounters) {
            if ($DeepMemCounters.CommittedBytes -gt 0) { $DeepRAMInUseCompressed = "$([math]::Round($DeepMemCounters.CommittedBytes / 1MB, 2)) MB" }
            if ($DeepMemCounters.AvailableBytes -gt 0) { $DeepRAMAvailableCommitted = "$([math]::Round($DeepMemCounters.AvailableBytes / 1MB, 2)) MB" }
            if ($DeepMemCounters.CacheBytes -gt 0) { $DeepRAMCached = "$([math]::Round($DeepMemCounters.CacheBytes / 1MB, 2)) MB" }
            if ($DeepMemCounters.PoolPagedBytes -gt 0) { $DeepRAMPagedPool = "$([math]::Round($DeepMemCounters.PoolPagedBytes / 1MB, 2)) MB" }
            if ($DeepMemCounters.PoolNonPagedBytes -gt 0) { $DeepRAMNonPagedPool = "$([math]::Round($DeepMemCounters.PoolNonPagedBytes / 1MB, 2)) MB" }
        }

        $DeepStorageRead = "N/A"
        $DeepStorageWrite = "N/A"
        $DeepStorageResponse = "N/A"
        try {
            $DeepDiskPerf = Get-Counter "\PhysicalDisk(_Total)\Disk Read Bytes/sec", "\PhysicalDisk(_Total)\Disk Write Bytes/sec", "\PhysicalDisk(_Total)\Avg. Disk sec/Transfer" -ErrorAction SilentlyContinue
            if ($DeepDiskPerf -and $DeepDiskPerf.CounterSamples) {
                $DeepReadBytes = ($DeepDiskPerf.CounterSamples | Where-Object { $_.Path -like "*Read Bytes*" }).CookedValue
                $DeepWriteBytes = ($DeepDiskPerf.CounterSamples | Where-Object { $_.Path -like "*Write Bytes*" }).CookedValue
                $DeepAvgSecTransfer = ($DeepDiskPerf.CounterSamples | Where-Object { $_.Path -like "*Avg. Disk sec*" }).CookedValue

                if ($DeepReadBytes -gt 0) {
                    $DeepStorageRead = if ($DeepReadBytes -gt 1GB) { "$([math]::Round($DeepReadBytes / 1GB, 2)) GB/s" } else { "$([math]::Round($DeepReadBytes / 1MB, 2)) MB/s" }
                }
                if ($DeepWriteBytes -gt 0) {
                    $DeepStorageWrite = if ($DeepWriteBytes -gt 1GB) { "$([math]::Round($DeepWriteBytes / 1GB, 2)) GB/s" } else { "$([math]::Round($DeepWriteBytes / 1MB, 2)) MB/s" }
                }
                if ($DeepAvgSecTransfer -gt 0) { $DeepStorageResponse = "$([math]::Round($DeepAvgSecTransfer * 1000, 2)) ms" }
            }
        }
        catch {}

        # Save AFTER log
        $LogAfterPath = "$ScriptDir\logs\after.log"
        @"
================================================================================
GANDIWIN SYSTEM CHECK - AFTER OPTIMIZATION
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================

[PERFORMANCE METRICS (AFTER OPTIMIZATION)]
Average CPU Load     : $CpuAverage
Average RAM Usage    : $RamAverage
Running Processes    : $TotalProcesses background processes

[MEMORY DETAILED (AFTER OPTIMIZATION)]
Virtual Memory Total: $VirtualMemTotal GB
Virtual Memory Used: $VirtualMemUsed GB
In Use (Compressed): $DeepRAMInUseCompressed
Available Committed: $DeepRAMAvailableCommitted
Cached: $DeepRAMCached
Paged Pool: $DeepRAMPagedPool
Non-Paged Pool: $DeepRAMNonPagedPool

[STORAGE PERFORMANCE (AFTER OPTIMIZATION)]
Read Speed: $DeepStorageRead
Write Speed: $DeepStorageWrite
Avg Response Time: $DeepStorageResponse
$(foreach ($Disk in $Disks) {
    $FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
    $TotalGB = [math]::Round($Disk.Size / 1GB, 2)
    $Percent = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 0)
    "Drive $($Disk.DeviceID): $FreeGB GB free of $TotalGB GB ($Percent%)"
})
================================================================================
"@ | Out-File -FilePath $LogAfterPath -Encoding UTF8

        Write-ActivityLog "After log saved: $LogAfterPath" "OK"
        Write-GandiStatus -Status "WAIT" -Message "Menyatukan data dan merender HTML Report..."
        
        # Baca template HTML
        if (Test-Path $AssetTemplate) {
            $HtmlContent = Get-Content $AssetTemplate -Raw
            
            # Ekstrak data menggunakan regex sederhana
            function Get-Metric ([string]$Content, [string]$Pattern) {
                if ($Content -match $Pattern) { return $matches[1].Trim() }
                return "N/A"
            }
            
            $TextB = Get-Content $LogBefore -Raw
            $TextA = Get-Content $LogAfterPath -Raw

            # Replace variable di HTML
            $HtmlContent = $HtmlContent.Replace('{{MODEL}}', (Get-Metric $TextB "Model\s*:\s*(.*)"))
            $HtmlContent = $HtmlContent.Replace('{{CPU_NAME}}', (Get-Metric $TextB "Model\s*:\s*(.*)"))
            $HtmlContent = $HtmlContent.Replace('{{DATE}}', (Get-Date -Format "dd MMMM yyyy"))
            
            $HtmlContent = $HtmlContent.Replace('{{B_CPU}}', (Get-Metric $TextB "Average CPU Load\s*:\s*(.*)"))
            $HtmlContent = $HtmlContent.Replace('{{A_CPU}}', (Get-Metric $TextA "Average CPU Load\s*:\s*(.*)"))
            
            $HtmlContent = $HtmlContent.Replace('{{B_RAM}}', (Get-Metric $TextB "Average RAM Usage\s*:\s*(.*)"))
            $HtmlContent = $HtmlContent.Replace('{{A_RAM}}', (Get-Metric $TextA "Average RAM Usage\s*:\s*(.*)"))
            
            $HtmlContent = $HtmlContent.Replace('{{B_PROC}}', (Get-Metric $TextB "Running Processes\s*:\s*(.*)"))
            $HtmlContent = $HtmlContent.Replace('{{A_PROC}}', (Get-Metric $TextA "Running Processes\s*:\s*(.*)"))
            
            $HtmlContent = $HtmlContent.Replace('{{B_COMPRESSED}}', (Get-Metric $TextB "In Use \(Compressed\)\s*:\s*(.*)"))
            $HtmlContent = $HtmlContent.Replace('{{A_COMPRESSED}}', (Get-Metric $TextA "In Use \(Compressed\)\s*:\s*(.*)"))
            
            $HtmlContent = $HtmlContent.Replace('{{B_READ}}', (Get-Metric $TextB "Read Speed:\s*(.*)"))
            $HtmlContent = $HtmlContent.Replace('{{A_READ}}', (Get-Metric $TextA "Read Speed:\s*(.*)"))
            
            $HtmlContent = $HtmlContent.Replace('{{B_WRITE}}', (Get-Metric $TextB "Write Speed:\s*(.*)"))
            $HtmlContent = $HtmlContent.Replace('{{A_WRITE}}', (Get-Metric $TextA "Write Speed:\s*(.*)"))

            # Save ke HTML
            $ReportPath = "$ScriptDir\logs\Optimization_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
            $HtmlContent | Out-File -FilePath $ReportPath -Encoding UTF8
            
            Write-GandiStatus -Status "OK" -Message "Report siap! Membuka browser untuk dicetak..."
            Start-Sleep -Seconds 2
            Invoke-Item $ReportPath
        } else {
            Write-Host "[ERROR] Template HTML tidak ditemukan di assets/template.html" -ForegroundColor Red
            Start-Sleep -Seconds 3
        }
    }
    "Q" { 
        Invoke-GandiTypewriter -Text "TERMINATING CONNECTION..." -DelayMs 10 -Color Red
        Start-Sleep -Seconds 1
        exit
    }
    default { 
        Write-GandiStatus -Status "FAIL" -Message "INVALID COMMAND SEQUENCE."
        Start-Sleep -Seconds 1 
    }
}
