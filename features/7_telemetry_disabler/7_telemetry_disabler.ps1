# ============================================================================
# GANDIWIN v3.0 - FEATURE 07: TELEMETRY DISABLER
# ============================================================================
# Advanced Windows Telemetry & Tracking Disabler
# Touches Registry, Services, Scheduled Tasks, Firewall, and Group Policies
# Target: Windows 10/11 with PowerShell 5.1+
# ============================================================================

# WAJIB ada di setiap script utama (Rule 1.4)
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    pause
    exit 1
}

# Resolve script directory
if ($PSScriptRoot -ne '') { $ScriptDir = $PSScriptRoot }
else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

# Import UI Module
$UIModule = "$ScriptDir\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

# Setup logging
$LogFile = "$ScriptDir\..\..\logs\menu.log"
if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }

function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMsg = "[$Timestamp] [$Level] [7_TELEMETRY] $Message"
    try { Add-Content -Path $LogFile -Value $LogMsg -ErrorAction SilentlyContinue } catch {}
}

# ============================================================================
# ADMIN CHECK
# ============================================================================
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================================
# TELEMETRY REGISTRY PATHS
# ============================================================================
$TelemetryRegistryPaths = @(
    # DiagTrack & Telemetry
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Type = "DWord"; Value = 0; Desc = "Disable Telemetry Level"},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowCommercialName"; Type = "String"; Value = "Enterprise"; Desc = "Set Commercial to Enterprise"},
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Type = "DWord"; Value = 0; Desc = "Current Version Telemetry"},
    
    # Windows Error Reporting
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"; Name = "Disabled"; Type = "DWord"; Value = 1; Desc = "Disable Windows Error Reporting"},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"; Name = "DoReport"; Type = "DWord"; Value = 0; Desc = "Disable Error Reports"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"; Name = "Disabled"; Type = "DWord"; Value = 1; Desc = "User WER Disabled"},
    
    # Feedback & Diagnostics
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "DoNotShowFeedbackNotifications"; Type = "DWord"; Value = 1; Desc = "No Feedback Notifications"},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "DisablePreDownloadExperience"; Type = "DWord"; Value = 1; Desc = "Disable Pre-Download Experience"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Siuf\Rules"; Name = "NumberOfSIUFInPeriod"; Type = "DWord"; Value = 0; Desc = "Disable SIUF Feedback"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Siuf\Rules"; Name = "PeriodInNanoSeconds"; Type = "DWord"; Value = 0; Desc = "Disable SIUF Period"},
    
    # Advertising ID
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Type = "DWord"; Value = 1; Desc = "Disable Advertising ID (Policy)"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Type = "DWord"; Value = 0; Desc = "Disable Advertising ID (User)"},
    
    # App Launch Tracking
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI"; Name = "DisableMFUTracking"; Type = "DWord"; Value = 1; Desc = "Disable App Launch Tracking"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackProgs"; Type = "DWord"; Value = 0; Desc = "Disable Start Menu Tracking"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackDocs"; Type = "DWord"; Value = 0; Desc = "Disable Recent Docs Tracking"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_ShowRecentDocs"; Type = "DWord"; Value = 0; Desc = "Hide Recent Documents"},
    
    # Location Tracking
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name = "DisableLocation"; Type = "DWord"; Value = 1; Desc = "Disable Location Services"},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name = "DisableLocationScripting"; Type = "DWord"; Value = 1; Desc = "Disable Location Scripting"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; Name = "Value"; Type = "String"; Value = "Deny"; Desc = "Deny Location Access"},
    
    # Cortana & Search
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortana"; Type = "DWord"; Value = 0; Desc = "Disable Cortana"},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCloudSearch"; Type = "DWord"; Value = 0; Desc = "Disable Cloud Search"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Type = "DWord"; Value = 0; Desc = "Disable Bing Search"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaConsent"; Type = "DWord"; Value = 0; Desc = "Reset Cortana Consent"},
    
    # Tailored Experiences
    @{Path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableTailoredExperiencesWithDiagnosticData"; Type = "DWord"; Value = 1; Desc = "Disable Tailored Experiences"},
    @{Path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableWindowsConsumerFeatures"; Type = "DWord"; Value = 1; Desc = "Disable Consumer Features"},
    @{Path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableCloudOptimizedContent"; Type = "DWord"; Value = 1; Desc = "Disable Cloud Content"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "ContentDeliveryAllowed"; Type = "DWord"; Value = 0; Desc = "Disable Content Delivery"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "OemPreInstalledAppsEnabled"; Type = "DWord"; Value = 0; Desc = "Disable OEM Apps"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "PreInstalledAppsEnabled"; Type = "DWord"; Value = 0; Desc = "Disable PreInstalled Apps"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SilentInstalledAppsEnabled"; Type = "DWord"; Value = 0; Desc = "Disable Silent Installs"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContentEnabled"; Type = "DWord"; Value = 0; Desc = "Disable Subscribed Content"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SoftLandingEnabled"; Type = "DWord"; Value = 0; Desc = "Disable Soft Landing"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SystemPaneSuggestionsEnabled"; Type = "DWord"; Value = 0; Desc = "Disable System Pane Suggestions"},
    
    # Windows Ink & Handwriting
    @{Path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"; Name = "RestrictImplicitInkCollection"; Type = "DWord"; Value = 1; Desc = "Restrict Ink Collection"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"; Name = "RestrictImplicitTextCollection"; Type = "DWord"; Value = 1; Desc = "Restrict Text Collection"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"; Name = "HarvestContacts"; Type = "DWord"; Value = 0; Desc = "Disable Contact Harvesting"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"; Name = "AcceptedPrivacyPolicy"; Type = "DWord"; Value = 0; Desc = "Reset Privacy Policy Acceptance"},
    
    # Sync Settings
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableSettingSync"; Type = "DWord"; Value = 2; Desc = "Disable Setting Sync"},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"; Name = "DisableSettingSyncUserOverride"; Type = "DWord"; Value = 1; Desc = "Enforce Sync Disable"},
    
    # Device Metadata
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata"; Name = "PreventDeviceMetadataFromNetwork"; Type = "DWord"; Value = 1; Desc = "Prevent Device Metadata"},
    
    # Windows Update Telemetry
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name = "DisableOSUpgrade"; Type = "DWord"; Value = 1; Desc = "Disable OS Upgrade Telemetry"},
    
    # App Telemetry
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Name = "AITEnable"; Type = "DWord"; Value = 0; Desc = "Disable App Telemetry"},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Name = "DisableInventory"; Type = "DWord"; Value = 1; Desc = "Disable Inventory"},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Name = "DisableUAR"; Type = "DWord"; Value = 1; Desc = "Disable UAR"},
    
    # WiFi Sense
    @{Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"; Name = "Value"; Type = "DWord"; Value = 0; Desc = "Disable WiFi HotSpot Reporting"},
    @{Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseNetworks"; Name = "Value"; Type = "DWord"; Value = 0; Desc = "Disable WiFi Sense"},
    
    # Maps & Auto Downloads
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps"; Name = "AutoDownloadAndUpdateMapData"; Type = "DWord"; Value = 0; Desc = "Disable Map Auto-Download"},
    
    # Delivery Optimization
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"; Name = "DODownloadMode"; Type = "DWord"; Value = 0; Desc = "Disable Delivery Optimization"},
    
    # Find My Device
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice"; Name = "AllowFindMyDevice"; Type = "DWord"; Value = 0; Desc = "Disable Find My Device"},
    
    # Speech & Typing
    @{Path = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"; Name = "HasAccepted"; Type = "DWord"; Value = 0; Desc = "Reset Speech Privacy"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Input\TIPC"; Name = "Enabled"; Type = "DWord"; Value = 0; Desc = "Disable TIPC"},
    
    # Diagnostic Data Viewer
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowDiagnosticData"; Type = "DWord"; Value = 0; Desc = "Disable Diagnostic Data"},
    
    # User Activity Upload
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "UploadUserActivities"; Type = "DWord"; Value = 0; Desc = "Disable Activity Upload"},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "PublishUserActivities"; Type = "DWord"; Value = 0; Desc = "Disable Activity Publish"}
)

# ============================================================================
# SERVICES TO DISABLE
# ============================================================================
$TelemetryServices = @(
    "DiagTrack",                    # Connected User Experiences and Telemetry
    "dmwappushservice",             # WAP Push Message Routing Service
    "lfsvc",                        # Geolocation Service
    "MapsBroker",                   # Downloaded Maps Manager
    "XblAuthManager",               # Xbox Live Auth Manager (telemetry)
    "XblGameSave",                  # Xbox Live Game Save
    "XboxNetApiSvc",                # Xbox Live Networking Service
    "RetailDemo",                   # Retail Demo Service
    "diagnosticshub.standardcollector.service",  # Diagnostic Hub
    "PcaSvc",                       # Program Compatibility Assistant
    "WerSvc"                        # Windows Error Reporting Service
)

# ============================================================================
# SCHEDULED TASKS TO DISABLE
# ============================================================================
$TelemetryTasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Application Experience\StartupAppTask",
    "\Microsoft\Windows\Application Experience\PcaPatchDbTask",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
    "\Microsoft\Windows\Customer Experience Improvement Program\BthCeipCentral",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Feedback\Siuf\DmClient",
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "\Microsoft\Windows\Feedback\IFM",
    "\Microsoft\Windows\Feedback\FeedbackCollector",
    "\Microsoft\Windows\Maps\MapsToastTask",
    "\Microsoft\Windows\Maps\MapsUpdateTask",
    "\Microsoft\Windows\Shell\FamilySafetyMonitor",
    "\Microsoft\Windows\Shell\FamilySafetyRefresh",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "\Microsoft\Windows\WindowsUpdate\AutomaticAppUpdate",
    "\Microsoft\Windows\Device Information\Device",
    "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataFlushing",
    "\Microsoft\Windows\Flighting\FeatureConfig\UsageDataReporting",
    "\Microsoft\Windows\PI\Sqm-Tasks",
    "\Microsoft\Windows\NetTrace\GatherNetworkInfo",
    "\Microsoft\Windows\Location\WindowsActionDialog",
    "\Microsoft\Office\OfficeTelemetryAgentLogOn",
    "\Microsoft\Office\OfficeTelemetryAgentFallBack"
)

# ============================================================================
# FIREWALL RULES FOR TELEMETRY ENDPOINTS
# ============================================================================
$TelemetryEndpoints = @(
    "vortex.data.microsoft.com",
    "vortex-win.data.microsoft.com",
    "telecommand.telemetry.microsoft.com",
    "telecommand.telemetry.microsoft.com.nsatc.net",
    "oca.telemetry.microsoft.com",
    "oca.telemetry.microsoft.com.nsatc.net",
    "sqm.telemetry.microsoft.com",
    "sqm.telemetry.microsoft.com.nsatc.net",
    "watson.telemetry.microsoft.com",
    "watson.telemetry.microsoft.com.nsatc.net",
    "watson.ppe.telemetry.microsoft.com",
    "watson.live.com",
    "telemetry.microsoft.com",
    "telemetry.appex.bing.net",
    "telemetry.urs.microsoft.com",
    "telemetry.services.visualstudio.com",
    "vortex.data.microsoft.com.akadns.net",
    "schema.management.azure.com",
    "settings-win.data.microsoft.com",
    "statsfe2.update.microsoft.com.akadns.net",
    "sls.update.microsoft.com.akadns.net",
    "fe2.update.microsoft.com.akadns.net",
    "diagnostics.support.microsoft.com",
    "corp.sts.microsoft.com",
    "statsfe1.ws.microsoft.com",
    "pre.footprintpredict.com",
    "feedback.microsoft-hohm.com",
    "feedback.search.microsoft.com",
    "feedback.windows.com",
    "ads.microsoft.com",
    "ads1.microsoft.com",
    "adnexus.net",
    "adsymptotic.com",
    "msedge.net",
    "choice.microsoft.com",
    "choice.microsoft.com.nsatc.net",
    "wdcp.microsoft.com",
    "wdcpalt.microsoft.com",
    "dns.msftncsi.com",
    "ipv6.msftncsi.com"
)

# ============================================================================
# APPLY REGISTRY TWEAKS
# ============================================================================
function Set-TelemetryRegistry {
    param([string]$Mode = "Disable")
    
    $Success = 0
    $Failed = 0
    
    foreach ($Item in $TelemetryRegistryPaths) {
        try {
            if (!(Test-Path $Item.Path)) {
                New-Item -Path $Item.Path -Force -ErrorAction SilentlyContinue | Out-Null
            }
            
            if ($Mode -eq "Disable") {
                Set-ItemProperty -Path $Item.Path -Name $Item.Name -Value $Item.Value -Type $Item.Type -Force
                Write-GandiStatus -Status "INFO" -Message "$($Item.Desc) - DISABLED"
            }
            else {
                # Restore default values
                $DefaultValue = switch ($Item.Type) {
                    "DWord" { 1 }
                    "String" { "Default" }
                    default { 0 }
                }
                Set-ItemProperty -Path $Item.Path -Name $Item.Name -Value $DefaultValue -Type $Item.Type -Force
                Write-GandiStatus -Status "INFO" -Message "$($Item.Desc) - RESTORED"
            }
            $Success++
            Write-ActivityLog "Registry: $($Item.Desc) - $Mode" "OK"
        }
        catch {
            $Failed++
            Write-GandiStatus -Status "FAIL" -Message "$($Item.Desc) - Failed: $($_.Exception.Message)"
            Write-ActivityLog "Registry FAILED: $($Item.Desc) - $($_.Exception.Message)" "FAIL"
        }
    }
    
    return @{Success = $Success; Failed = $Failed}
}

# ============================================================================
# MANAGE SERVICES
# ============================================================================
function Set-TelemetryServices {
    param([string]$Mode = "Disable")
    
    $Success = 0
    $Failed = 0
    
    foreach ($Service in $TelemetryServices) {
        try {
            $Svc = Get-Service -Name $Service -ErrorAction SilentlyContinue
            if ($Svc) {
                if ($Mode -eq "Disable") {
                    Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
                    Write-GandiStatus -Status "INFO" -Message "Service: $Service - DISABLED"
                }
                else {
                    Set-Service -Name $Service -StartupType Manual -ErrorAction SilentlyContinue
                    Write-GandiStatus -Status "INFO" -Message "Service: $Service - RESTORED"
                }
                $Success++
                Write-ActivityLog "Service: $Service - $Mode" "OK"
            }
            else {
                Write-GandiStatus -Status "WARN" -Message "Service: $Service - Not Found"
            }
        }
        catch {
            $Failed++
            Write-GandiStatus -Status "FAIL" -Message "Service: $Service - $($_.Exception.Message)"
            Write-ActivityLog "Service FAILED: $Service - $($_.Exception.Message)" "FAIL"
        }
    }
    
    return @{Success = $Success; Failed = $Failed}
}

# ============================================================================
# MANAGE SCHEDULED TASKS
# ============================================================================
function Set-TelemetryTasks {
    param([string]$Mode = "Disable")
    
    $Success = 0
    $Failed = 0
    
    foreach ($Task in $TelemetryTasks) {
        try {
            $TaskObj = Get-ScheduledTask -TaskName ($Task -split '\\')[-1] -TaskPath ($Task -replace '\\[^\\]*$','\') -ErrorAction SilentlyContinue
            if ($TaskObj) {
                if ($Mode -eq "Disable") {
                    Disable-ScheduledTask -InputObject $TaskObj -ErrorAction SilentlyContinue
                    Write-GandiStatus -Status "INFO" -Message "Task: $Task - DISABLED"
                }
                else {
                    Enable-ScheduledTask -InputObject $TaskObj -ErrorAction SilentlyContinue
                    Write-GandiStatus -Status "INFO" -Message "Task: $Task - RESTORED"
                }
                $Success++
                Write-ActivityLog "Task: $Task - $Mode" "OK"
            }
            else {
                Write-GandiStatus -Status "WARN" -Message "Task: $Task - Not Found"
            }
        }
        catch {
            $Failed++
            Write-GandiStatus -Status "FAIL" -Message "Task: $Task - $($_.Exception.Message)"
            Write-ActivityLog "Task FAILED: $Task - $($_.Exception.Message)" "FAIL"
        }
    }
    
    return @{Success = $Success; Failed = $Failed}
}

# ============================================================================
# MANAGE FIREWALL RULES
# ============================================================================
function Set-TelemetryFirewall {
    param([string]$Mode = "Disable")
    
    $Success = 0
    $Failed = 0
    
    foreach ($Endpoint in $TelemetryEndpoints) {
        try {
            $RuleName = "GandiWin_Telemetry_Block_$($Endpoint -replace '\.', '_')"
            
            if ($Mode -eq "Disable") {
                # Check if rule exists
                $ExistingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
                if ($ExistingRule) {
                    Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
                }
                
                # Create new blocking rule
                New-NetFirewallRule -DisplayName $RuleName -Direction Outbound -Action Block -RemoteAddress $Endpoint -Enabled True -ErrorAction SilentlyContinue
                Write-GandiStatus -Status "INFO" -Message "Firewall: Block $Endpoint"
                $Success++
                Write-ActivityLog "Firewall: Block $Endpoint" "OK"
            }
            else {
                # Remove blocking rule
                $ExistingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
                if ($ExistingRule) {
                    Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
                    Write-GandiStatus -Status "INFO" -Message "Firewall: Removed block for $Endpoint"
                    $Success++
                    Write-ActivityLog "Firewall: Removed $Endpoint" "OK"
                }
            }
        }
        catch {
            $Failed++
            Write-GandiStatus -Status "FAIL" -Message "Firewall: $Endpoint - $($_.Exception.Message)"
            Write-ActivityLog "Firewall FAILED: $Endpoint - $($_.Exception.Message)" "FAIL"
        }
    }
    
    return @{Success = $Success; Failed = $Failed}
}

# ============================================================================
# FULL TELEMETRY DISABLE
# ============================================================================
function Invoke-FullTelemetryDisable {
    Write-GandiStatus -Status "WAIT" -Message "Starting FULL telemetry disable operation..."
    Write-ActivityLog "FULL TELEMETRY DISABLE started" "WARN"
    
    $Confirm = Read-Host "  Type YES to confirm (this will disable all telemetry)"
    if ($Confirm -ne "YES") {
        Write-GandiStatus -Status "INFO" -Message "Operation cancelled by user"
        return
    }
    
    Write-Host ""
    Write-GandiStatus -Status "WAIT" -Message "Phase 1: Registry Tweaks..."
    $RegResult = Set-TelemetryRegistry -Mode "Disable"
    
    Write-Host ""
    Write-GandiStatus -Status "WAIT" -Message "Phase 2: Services..."
    $SvcResult = Set-TelemetryServices -Mode "Disable"
    
    Write-Host ""
    Write-GandiStatus -Status "WAIT" -Message "Phase 3: Scheduled Tasks..."
    $TaskResult = Set-TelemetryTasks -Mode "Disable"
    
    Write-Host ""
    Write-GandiStatus -Status "WAIT" -Message "Phase 4: Firewall Rules..."
    $FwResult = Set-TelemetryFirewall -Mode "Disable"
    
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-GandiStatus -Status "OK" -Message "REGISTRY: $($RegResult.Success) applied, $($RegResult.Failed) failed"
    Write-GandiStatus -Status "OK" -Message "SERVICES: $($SvcResult.Success) disabled, $($SvcResult.Failed) failed"
    Write-GandiStatus -Status "OK" -Message "TASKS: $($TaskResult.Success) disabled, $($TaskResult.Failed) failed"
    Write-GandiStatus -Status "OK" -Message "FIREWALL: $($FwResult.Success) rules created, $($FwResult.Failed) failed"
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    
    Write-ActivityLog "FULL TELEMETRY DISABLE completed" "OK"
    Write-GandiStatus -Status "WARN" -Message "REBOOT REQUIRED for changes to take effect!"
    
    Read-Host "  Press ENTER to continue" | Out-Null
}

# ============================================================================
# RESTORE ALL TELEMETRY
# ============================================================================
function Invoke-RestoreTelemetry {
    Write-GandiStatus -Status "WAIT" -Message "Starting telemetry RESTORE operation..."
    Write-ActivityLog "RESTORE TELEMETRY started" "WARN"
    
    $Confirm = Read-Host "  Type YES to confirm (this will restore all telemetry)"
    if ($Confirm -ne "YES") {
        Write-GandiStatus -Status "INFO" -Message "Operation cancelled by user"
        return
    }
    
    Write-Host ""
    Write-GandiStatus -Status "WAIT" -Message "Phase 1: Restoring Registry..."
    $RegResult = Set-TelemetryRegistry -Mode "Restore"
    
    Write-Host ""
    Write-GandiStatus -Status "WAIT" -Message "Phase 2: Restoring Services..."
    $SvcResult = Set-TelemetryServices -Mode "Restore"
    
    Write-Host ""
    Write-GandiStatus -Status "WAIT" -Message "Phase 3: Restoring Tasks..."
    $TaskResult = Set-TelemetryTasks -Mode "Restore"
    
    Write-Host ""
    Write-GandiStatus -Status "WAIT" -Message "Phase 4: Removing Firewall Rules..."
    $FwResult = Set-TelemetryFirewall -Mode "Restore"
    
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-GandiStatus -Status "OK" -Message "REGISTRY: $($RegResult.Success) restored"
    Write-GandiStatus -Status "OK" -Message "SERVICES: $($SvcResult.Success) restored"
    Write-GandiStatus -Status "OK" -Message "TASKS: $($TaskResult.Success) restored"
    Write-GandiStatus -Status "OK" -Message "FIREWALL: $($FwResult.Success) rules removed"
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    
    Write-ActivityLog "RESTORE TELEMETRY completed" "OK"
    Write-GandiStatus -Status "WARN" -Message "REBOOT REQUIRED for changes to take effect!"
    
    Read-Host "  Press ENTER to continue" | Out-Null
}

# ============================================================================
# SELECTIVE DISABLE
# ============================================================================
function Invoke-SelectiveDisable {
    while ($true) {
        [Console]::Clear()
        Show-GandiHeader -Title "SELECTIVE TELEMETRY DISABLE"
        
        Write-Host "  Select which components to disable:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] Registry Tweaks Only" -ForegroundColor Cyan
        Write-Host "  [2] Services Only" -ForegroundColor Cyan
        Write-Host "  [3] Scheduled Tasks Only" -ForegroundColor Cyan
        Write-Host "  [4] Firewall Rules Only" -ForegroundColor Cyan
        Write-Host "  [5] Registry + Services" -ForegroundColor Yellow
        Write-Host "  [6] Registry + Services + Tasks" -ForegroundColor Yellow
        Write-Host "  [7] ALL Components" -ForegroundColor Red
        Write-Host ""
        Write-Host "  [0] BACK" -ForegroundColor Gray
        Write-Host ""
        
        $Choice = Read-Host "  Select option"
        
        switch ($Choice) {
            '1' { Set-TelemetryRegistry -Mode "Disable" }
            '2' { Set-TelemetryServices -Mode "Disable" }
            '3' { Set-TelemetryTasks -Mode "Disable" }
            '4' { Set-TelemetryFirewall -Mode "Disable" }
            '5' { 
                Set-TelemetryRegistry -Mode "Disable"
                Set-TelemetryServices -Mode "Disable"
            }
            '6' {
                Set-TelemetryRegistry -Mode "Disable"
                Set-TelemetryServices -Mode "Disable"
                Set-TelemetryTasks -Mode "Disable"
            }
            '7' {
                Set-TelemetryRegistry -Mode "Disable"
                Set-TelemetryServices -Mode "Disable"
                Set-TelemetryTasks -Mode "Disable"
                Set-TelemetryFirewall -Mode "Disable"
            }
            '0' { return }
            default { Write-GandiStatus -Status "FAIL" -Message "Invalid option"; Start-Sleep -Seconds 1 }
        }
        
        Write-Host ""
        Write-GandiStatus -Status "OK" -Message "Operation completed!"
        Start-Sleep -Seconds 2
    }
}

# ============================================================================
# CHECK CURRENT STATUS
# ============================================================================
function Get-TelemetryStatus {
    Write-GandiStatus -Status "WAIT" -Message "Scanning telemetry status..."
    Start-Sleep -Milliseconds 500
    
    Write-Host ""
    Show-GandiBox -Title "TELEMETRY STATUS CHECK"
    
    # Check DiagTrack service
    $DiagTrack = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
    $DiagStatus = if ($DiagTrack.StartType -eq "Disabled") { "DISABLED" } else { "ENABLED" }
    $DiagColor = if ($DiagTrack.StartType -eq "Disabled") { "Green" } else { "Red" }
    Show-GandiKeyValue "DiagTrack Service" $DiagStatus "White" $DiagColor
    
    # Check telemetry registry
    try {
        $TeleLevel = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
        $TeleStatus = if ($TeleLevel.AllowTelemetry -eq 0) { "DISABLED (0)" } else { "ENABLED ($($TeleLevel.AllowTelemetry))" }
        $TeleColor = if ($TeleLevel.AllowTelemetry -eq 0) { "Green" } else { "Red" }
        Show-GandiKeyValue "Telemetry Level" $TeleStatus "White" $TeleColor
    }
    catch {
        Show-GandiKeyValue "Telemetry Level" "Not Configured" "White" "Yellow"
    }
    
    # Check scheduled tasks
    $DisabledTasks = 0
    foreach ($Task in $TelemetryTasks) {
        try {
            $TaskObj = Get-ScheduledTask -TaskName ($Task -split '\\')[-1] -TaskPath ($Task -replace '\\[^\\]*$','\') -ErrorAction SilentlyContinue
            if ($TaskObj.State -eq "Disabled") { $DisabledTasks++ }
        }
        catch {}
    }
    Show-GandiKeyValue "Disabled Tasks" "$DisabledTasks / $($TelemetryTasks.Count)" "White" "Cyan"
    
    # Check firewall rules
    $FirewallRules = (Get-NetFirewallRule -DisplayName "GandiWin_Telemetry_*" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq "True" }).Count
    Show-GandiKeyValue "Firewall Rules" "$FirewallRules active" "White" "Cyan"
    
    Write-Host ""
    Write-GandiStatus -Status "INFO" -Message "Status check complete"
    Write-ActivityLog "Telemetry status check performed" "INFO"
    
    Read-Host "  Press ENTER to continue" | Out-Null
}

# ============================================================================
# MAIN MENU
# ============================================================================
while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: TELEMETRY DISABLER"
    Show-GandiHeader -Title "07 TELEMETRY DISABLER"
    
    Write-ActivityLog "Telemetry Disabler module launched"
    
    # Admin status
    $IsAdmin = Test-IsAdmin
    $AdminText = if ($IsAdmin) { "YES - Full access" } else { "NO - Limited functionality" }
    $AdminColor = if ($IsAdmin) { "Green" } else { "Red" }
    Show-GandiKeyValue "Administrator" $AdminText "White" $AdminColor
    
    Write-Host ""
    Show-GandiBox -Title "COVERAGE"
    Write-Host "    Registry Paths  : $($TelemetryRegistryPaths.Count)" -ForegroundColor Cyan
    Write-Host "    Services        : $($TelemetryServices.Count)" -ForegroundColor Cyan
    Write-Host "    Scheduled Tasks : $($TelemetryTasks.Count)" -ForegroundColor Cyan
    Write-Host "    Firewall Rules  : $($TelemetryEndpoints.Count)" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  [ AGGRESSIVE MODE ]" -ForegroundColor Red
    Write-Host "  [1] DISABLE ALL TELEMETRY (Full Block)" -ForegroundColor DarkRed
    Write-Host ""
    Write-Host "  [ RESTORE ]" -ForegroundColor Yellow
    Write-Host "  [2] RESTORE ALL TELEMETRY (Windows Default)" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  [ SELECTIVE ]" -ForegroundColor Cyan
    Write-Host "  [3] Selective Disable (Choose Components)" -ForegroundColor White
    Write-Host ""
    Write-Host "  [ INFO ]" -ForegroundColor Gray
    Write-Host "  [4] Check Current Telemetry Status" -ForegroundColor White
    Write-Host "  [5] View Blocked Endpoints" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] BACK TO MENU" -ForegroundColor Yellow
    Write-Host ""
    
    $Choice = Read-Host "  AWAITING COMMAND"
    
    Write-Host ""
    switch ($Choice) {
        '1' { Invoke-FullTelemetryDisable }
        '2' { Invoke-RestoreTelemetry }
        '3' { Invoke-SelectiveDisable }
        '4' { Get-TelemetryStatus }
        '5' {
            Show-GandiHeader -Title "BLOCKED TELEMETRY ENDPOINTS"
            Write-Host "  The following domains are blocked via firewall:" -ForegroundColor White
            Write-Host ""
            $TelemetryEndpoints | ForEach-Object { Write-Host "    - $_" -ForegroundColor DarkGray }
            Write-Host ""
            Read-Host "  Press ENTER to continue" | Out-Null
        }
        '0' {
            Write-ActivityLog "Telemetry Disabler module exited"
            Invoke-GandiTypewriter -Text "CLOSING TELEMETRY DISABLER..." -DelayMs 10 -Color Red
            Start-Sleep -Seconds 1
            exit
        }
        default { Write-GandiStatus -Status "FAIL" -Message "Invalid command."; Start-Sleep -Seconds 1 }
    }
}
