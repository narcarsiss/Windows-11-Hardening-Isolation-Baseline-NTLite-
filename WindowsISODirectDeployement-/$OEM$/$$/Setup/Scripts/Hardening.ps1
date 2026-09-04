<#
.SYNOPSIS
    Hardening, Performance, Memory Footprint & Quality-of-Life Baseline Script for Windows 11 Enterprise Deployments.

.DESCRIPTION
    Hardening.ps1 is a post-installation deployment script executed during the oobeSystem pass via autounattend.xml's FirstLogonCommands phase.
    It establishes a hardened, low-latency, production-ready endpoint configuration for Windows 11.
    
    Key operational functions include:
      - Default credential warning dialogs and privileged account logon banners.
      - OEM branding, telemetry/bloatware neutralization, and Delivery Optimization P2P blocks.
      - Disabling AI, Copilot, Windows Recall, and Widgets infrastructure.
      - Network protocol hardening (LLMNR disablement, SMB3 signing enforcement, IPv6 binding removal).
      - Storage and performance tuning (HAGS, NTFS timestamp updates, Storage Sense, Fast Startup disablement).
      - Memory footprint optimizations (dynamic SvcHost process grouping threshold, NDU driver memory leak patch, executive paging enforcement).
      - Enterprise browser group policy enforcement (Microsoft Edge & Brave Browser).
      - Advanced Attack Surface Reduction (ASR) rules, Virtualization-Based Security (VBS), and LSA Protection (RunAsPPL).
      - System-wide audio optimization and self-destructing 7-day Bluetooth stereo monitor task.
      - Default User Profile (NTUSER.DAT) registry modifications for future user profile provisioning.

.PARAMETER None
    This script takes no parameters and executes directly within the elevated SYSTEM / Administrator context.

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Windows\Setup\Scripts\Hardening.ps1"
    Executes the hardening pipeline silently during the first administrative logon.

.NOTES
    File Name      : Hardening.ps1
    Author         : Damien John O'Brien / Moosehead Studio
    Target OS      : Windows 11 Pro / Enterprise (Build 22H2 / 23H2 / 24H2)
    Execution Pass : oobeSystem (FirstLogonCommands)
    Log Path       : C:\Windows\Panther\HardeningAndOptimization.log
    Prerequisites  : Staged via USB ($OEM$\$$\Setup\Scripts\Hardening.ps1) to %windir%\Setup\Scripts\

.LINK
    https://github.com/narcarsiss/Windows-11-Hardening-Isolation-Baseline-NTLite-
#>

# =========================================================================================
# SECTION 1: EXECUTION ENVIRONMENT & LOGGING INITIALIZATION
# =========================================================================================

# Initialize transcript logging to capture stdout/stderr for audit compliance during deployment
$LogFile = "$env:SystemDrive\Windows\Panther\HardeningAndOptimization.log"
Start-Transcript -Path $LogFile -Append -ErrorAction SilentlyContinue

# Establish default template passwords for operational validation prompts
$defaultAdminPass = 'AdminSecurePass2026!'
$defaultOpPass    = 'OperatorSecurePass2026!'

# Load WPF assemblies to render interactive security warning dialogs
[System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework') | Out-Null
[System.Windows.MessageBox]::Show(
    'SECURITY WARNING: This endpoint was deployed using default template passwords (AdminSecurePass2026! / OperatorSecurePass2026!). Please update them immediately before production use!',
    'Moosehead Studio - Default Credentials Detected',
    'OK',
    'Warning'
) | Out-Null

# Register a persistent scheduled task to display a security reminder whenever the local Administrator signs in
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -Command "[System.Reflection.Assembly]::LoadWithPartialName(''PresentationFramework''); [System.Windows.MessageBox]::Show(''Warning: This is a privileged account. Changes made while signed in may affect all users and system security.`n`nAdministrative access only. Use this account only when required for approved system maintenance.`n`nDo not use this account for email, web browsing, or routine work.'', ''Moosehead Studio - High Privilege Security Warning'', ''OK'', ''Warning'')"'
$trigger = New-ScheduledTaskTrigger -AtLogOn -User 'Administrator'
$settings = New-ScheduledTaskSettingsOption -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName 'AdminLoginSecurityWarning' -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force | Out-Null

# =========================================================================================
# SECTION 2: OEM BRANDING & SYSTEM INFORMATION
# =========================================================================================

# Populate System Properties (sysdm.cpl) with custom organizational branding and repository metadata
$oemPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'
New-Item -Path $oemPath -Force | Out-Null
Set-ItemProperty -Path $oemPath -Name 'Manufacturer' -Value 'Moosehead Studio' -Force
Set-ItemProperty -Path $oemPath -Name 'Model' -Value 'Hardened Windows 11 Endpoint' -Force
Set-ItemProperty -Path $oemPath -Name 'SupportURL' -Value 'https://github.com/narcarsiss/Windows-11-Hardening-Isolation-Baseline-NTLite-' -Force
Set-ItemProperty -Path $oemPath -Name 'Appreciation' -Value 'Thank you for using our security endpoint config' -Force

# =========================================================================================
# SECTION 3: TELEMETRY, CONSUMER BLOATWARE & FEATURE NEUTRALIZATION
# =========================================================================================

# Block OEM pre-installed app auto-provisioning and consumer features
reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v 'OemPreInstalledAppsEnabled' /t REG_DWORD /d '0' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' /v 'DisableWindowsConsumerFeatures' /t REG_DWORD /d '1' /f 2>&1 | Out-Null

# Enforce a completely clean, unpinned Start Menu baseline
reg add 'HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start' /v 'ConfigureStartPins' /t REG_SZ /d '{"pinnedList": [{}]}' /f 2>&1 | Out-Null

# Disable cloud-optimized consumer content, feeds, and Cortana background integrations
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' /v 'DisableConsumerAccountStateContent' /t REG_DWORD /d '1' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' /v 'DisableCloudOptimizedContent' /t REG_DWORD /d '1' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' /v 'EnableFeeds' /t REG_DWORD /d '0' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'AllowCortana' /t REG_DWORD /d '0' /f 2>&1 | Out-Null

# Block automatic Microsoft Teams consumer installation and restrict telemetry reporting
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Teams' /v 'DisableInstallation' /t REG_DWORD /d '1' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v 'AllowTelemetry' /t REG_DWORD /d '0' /f 2>&1 | Out-Null
reg add 'HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice' /v 'Start' /t REG_DWORD /d '4' /f 2>&1 | Out-Null

# Disable Delivery Optimization Peer-to-Peer uploading (DODownloadMode = 0: HTTP / Simple Mode)
$DoPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
if (-not (Test-Path $DoPath)) { New-Item -Path $DoPath -Force | Out-Null }
Set-ItemProperty -Path $DoPath -Name 'DODownloadMode' -Value 0 -Type DWord -Force

# Disable Find My Device tracking features on desktop endpoints
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' -Name 'AllowFindMyDevice' -Value 0 -Force

# =========================================================================================
# SECTION 4: AI, COPILOT, RECALL & WIDGETS ISOLATION
# =========================================================================================

# Block Windows Recall snapshotting data providers
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableRecallDataProviders' -Value 1 -Force

# Disable Windows Copilot infrastructure globally
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value 1 -Force

# Disable online search suggestions in File Explorer and Windows Search
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value 1 -Force

# Fully deactivate Windows Widgets and News/Interests web feed overlays
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowWidgets' -Value 0 -Force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Value 0 -Force

# =========================================================================================
# SECTION 5: NETWORK HARDENING & PROTOCOL OPTIMIZATION
# =========================================================================================

# Disable Link-Local Multicast Name Resolution (LLMNR) to mitigate NTLM relay attacks (Responder)
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -Name 'EnableMulticast' -Value 0 -Force

# Unbind IPv6 protocol on active network interfaces
Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | Disable-NetAdapterBinding -ErrorAction SilentlyContinue

# Remove legacy SMB1 feature and enforce mandatory SMB3 message signing for clients and servers
Disable-WindowsOptionalFeature -Online -FeatureName 'SMB1Protocol' -NoRestart -ErrorAction SilentlyContinue | Out-Null
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force -ErrorAction SilentlyContinue
Set-SmbClientConfiguration -RequireSecuritySignature $true -Force -ErrorAction SilentlyContinue

# Remove network packet processing caps for non-multimedia workloads
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Value 0xFFFFFFFF -Force

# Enable TCP Receive Side Scaling (RSS) and TCP Window Auto-Tuning
netsh int tcp set global autotuninglevel=normal 1>nul 2>nul
netsh int tcp set global rss=enabled 1>nul 2>nul

# =========================================================================================
# SECTION 6: WINDOWS UPDATE DRIVER POLICY & HARDWARE METADATA
# =========================================================================================

# Permit Windows Update driver searching while blocking non-essential device metadata downloads from remote servers
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching' -Name 'DontSearchWindowsUpdate' -Value 0 -Force
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions' -Name 'PreventDeviceMetadataFromNetwork' -Value 1 -Force

# =========================================================================================
# SECTION 7: GAMING OVERLAYS & DVR SERVICE NEUTRALIZATION
# =========================================================================================

# Disable GameDVR recording services and background GameBar presence monitors
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR' /v 'AllowGameDVR' /t REG_DWORD /d '0' /f 2>&1 | Out-Null
reg add 'HKLM\SYSTEM\CurrentControlSet\Services\BcastDVRUserService' /v 'Start' /t REG_DWORD /d '4' /f 2>&1 | Out-Null
reg add 'HKLM\SYSTEM\CurrentControlSet\Services\GameBarPresenceWriter' /v 'Start' /t REG_DWORD /d '4' /f 2>&1 | Out-Null

# =========================================================================================
# SECTION 8: SYSTEM PERFORMANCE, LATENCY & STORAGE TUNING
# =========================================================================================

# Reclaim ~7GB of drive space by disabling Windows Reserved Storage
Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue | Out-Null

# Disable SysMain (Superfetch) service to eliminate unnecessary background disk write cycles on SSD/NVMe drives
Set-Service -Name 'SysMain' -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name 'SysMain' -Force -ErrorAction SilentlyContinue

# Disable dynamic tick interrupts to lock timer interrupts and reduce micro-stuttering latency
bcdedit /set dynamictick no 1>nul 2>nul

# Enable Hardware-Accelerated GPU Scheduling (HAGS)
$HagsPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
if (-not (Test-Path $HagsPath)) { New-Item -Path $HagsPath -Force | Out-Null }
Set-ItemProperty -Path $HagsPath -Name 'HwSchMode' -Value 2 -Force

# Disable NTFS Last Access Timestamp writes to reduce drive write overhead during file operations
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'NtfsDisableLastAccessUpdate' -Value 1 -Force

# Turn off Fast Startup (Hiberboot) to force clean driver reloads on shutdown and prevent memory leaks
$SessionPowerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
if (-not (Test-Path $SessionPowerPath)) { New-Item -Path $SessionPowerPath -Force | Out-Null }
Set-ItemProperty -Path $SessionPowerPath -Name 'HiberbootEnabled' -Value 0 -Force

# Configure Storage Sense policies to automatically purge temporary files older than 30 days
$StorageSensePath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense'
if (-not (Test-Path $StorageSensePath)) { New-Item -Path $StorageSensePath -Force | Out-Null }
Set-ItemProperty -Path $StorageSensePath -Name 'AllowStorageSenseGlobal' -Value 1 -Force
Set-ItemProperty -Path $StorageSensePath -Name 'ConfigStorageSenseCloudContentCleanThreshold' -Value 30 -Force

# =========================================================================================
# SECTION 9: AUDIO SYSTEM HARDENING & AUTORUN PROTECTION
# =========================================================================================

# Disable Protected Audio Processing (Home Theater DRM driver layer) system-wide
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio' -Name 'DisableProtectedAudioProcessing' -Value 1 -Force

# Disable AutoRun and AutoPlay globally across all removable drives and volume types
$ExplorerPolicyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
if (-not (Test-Path $ExplorerPolicyPath)) { New-Item -Path $ExplorerPolicyPath -Force | Out-Null }
Set-ItemProperty -Path $ExplorerPolicyPath -Name 'NoDriveTypeAutoRun' -Value 255 -Type DWord -Force
Set-ItemProperty -Path $ExplorerPolicyPath -Name 'NoAutorun' -Value 1 -Type DWord -Force

$WinExplorerPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
if (-not (Test-Path $WinExplorerPolicyPath)) { New-Item -Path $WinExplorerPolicyPath -Force | Out-Null }
Set-ItemProperty -Path $WinExplorerPolicyPath -Name 'NoAutoplayfornonVolume' -Value 1 -Type DWord -Force

# =========================================================================================
# SECTION 10: MEMORY FOOTPRINT & SERVICE OPTIMIZATIONS
# =========================================================================================

# Dynamically calculate physical RAM and configure the SvcHost split threshold to consolidate service processes
$TotalRamKB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB)
if ($TotalRamKB -gt 4194304) {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'SvcHostSplitThresholdInKB' -Value $TotalRamKB -Type DWord -Force
} else {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'SvcHostSplitThresholdInKB' -Value 3800000 -Type DWord -Force
}

# Disable Network Data Usage (NDU) monitoring driver to resolve non-paged pool RAM leaks during high-throughput network operations
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu' -Name 'Start' -Value 4 -Force

# Prevent executive kernel driver paging to keep OS drivers resident in physical RAM
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'DisablePagingExecutive' -Value 1 -Force

# Disable non-essential background services (Print Spooler is explicitly retained for physical printing capability)
Set-Service -Name 'MapsBroker' -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name 'MapsBroker' -Force -ErrorAction SilentlyContinue
Set-Service -Name 'RetailDemo' -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name 'RetailDemo' -Force -ErrorAction SilentlyContinue
Set-Service -Name 'DiagTrack' -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name 'DiagTrack' -Force -ErrorAction SilentlyContinue

# =========================================================================================
# SECTION 11: BLUETOOTH STEREO MONITOR PAYLOAD INJECTION
# =========================================================================================

# Inject a self-destructing background script payload that forces Bluetooth audio devices into A2DP High-Quality Stereo mode
$MonitorScriptPath = "$env:SystemRoot\System32\BluetoothStereoMonitor.ps1"
$BtTaskName = "BluetoothStereoForceMonitor"

$MonitorScriptContent = @'
# Internal Persistent Bluetooth Engine
$LogFile = "$env:SystemDrive\Windows\Panther\BluetoothMonitor.log"
$HandsFreeGuid = "{0000111e-0000-1000-8000-00805f9b34fb}"
$BtRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Devices"
$InstallDateFile = "$env:SystemRoot\System32\BtMonitorInstallDate.txt"

if (-not (Test-Path $InstallDateFile)) {
    Get-Date -Format "yyyy-MM-dd" | Out-File $InstallDateFile -Force
    $InstallDate = Get-Date
} else {
    $InstallDate = Get-Date (Get-Content $InstallDateFile -Raw).Trim()
}

Add-Content -Path $LogFile -Value "$((Get-Date).ToString()): Cycle active. Checking for Bluetooth hardware changes..."

if (Test-Path $BtRegPath) {
    $devices = Get-ChildItem -Path $BtRegPath
    foreach ($device in $devices) {
        $servicesPath = Join-Path $device.PsPath "Services"
        if (Test-Path $servicesPath) {
            if (Get-ItemProperty -Path $servicesPath -Name $HandsFreeGuid -ErrorAction SilentlyContinue) {
                $currentVal = (Get-ItemProperty -Path $servicesPath -Name $HandsFreeGuid).$HandsFreeGuid
                if ($currentVal -ne 0) {
                    Set-ItemProperty -Path $servicesPath -Name $HandsFreeGuid -Value 0 -Force
                    Add-Content -Path $LogFile -Value "[✓] Found device $($device.PSChildName). Forcefully disabled Hands-Free Telephony."
                    Restart-Service -Name "Audiosrv" -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

if ((Get-Date) -gt $InstallDate.AddDays(7)) {
    Add-Content -Path $LogFile -Value "--- 7 Days reached. Executing clean self-destruction protocol. ---"
    Unregister-ScheduledTask -TaskName "BluetoothStereoForceMonitor" -Confirm:$false -ErrorAction SilentlyContinue
    Remove-Item -Path $InstallDateFile -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
    Exit
}
'@

$MonitorScriptContent | Out-File -FilePath $MonitorScriptPath -Encoding utf8 -Force

# Register the hidden scheduled task under NT AUTHORITY\SYSTEM context to run at user logon for 7 days
$BtTaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$MonitorScriptPath`""
$BtTaskTrigger = New-ScheduledTaskTrigger -AtLogOn
$BtTaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $BtTaskName -Action $BtTaskAction -Trigger $BtTaskTrigger -Settings $BtTaskSettings -User "NT AUTHORITY\SYSTEM" -Force | Out-Null

# =========================================================================================
# SECTION 12: DEFAULT USER PROFILE (NTUSER.DAT) REVISION
# =========================================================================================

# Mount default user profile hive to enforce preferences for all newly created user accounts
$defaultUserHive = 'C:\Users\Default\NTUSER.DAT'
if (Test-Path $defaultUserHive) {
    reg load 'HKU\DefaultUser' $defaultUserHive 2>&1 | Out-Null
    
    # Set menu display delay to 20ms for faster UI navigation
    New-Item -Path 'Registry::HKU\DefaultUser\Control Panel\Desktop' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '20' -Force

    # Taskbar and File Explorer preferences (Show file extensions, launch to This PC, combine taskbar icons)
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarGlomLevel' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarDa' -Value 1 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LastActiveClick' -Value 1 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Value 1 -Force

    # Disable AutoRun for new user profiles
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoDriveTypeAutoRun' -Value 255 -Force

    # Disable Spatial Audio globally for new user profiles
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Multimedia\Audio' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Multimedia\Audio' -Name 'SpatialSoundEnabled' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Multimedia\Audio' -Name 'DisableSpatial' -Value 1 -Force

    # Disable window transparency effects to reduce GPU rendering load
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0 -Force

    # Disable Bing search inside Start menu and hide search box suggestions
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Search' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0 -Force

    # Disable consumer advertising tracking ID
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 -Force

    # Expand notification tray overflow menu by default
    New-Item -Path 'Registry::HKU\DefaultUser\Control Panel\NotifyIconSettings' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Control Panel\NotifyIconSettings' -Name 'EnableAutoTray' -Value 0 -Force

    # Show Recycle Bin icon on desktop
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name '{645FF040-5081-101B-9F08-00AA002F954E}' -Value 0 -Force

    # Block content delivery suggestions and silent app installations
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'PreInstalledAppsEnabled' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SilentInstalledAppsEnabled' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContentEnabled' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'ContentDeliveryAllowed' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'PreInstalledAppsEverEnabled' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SoftLandingEnabled' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SystemPaneSuggestionsEnabled' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenEnabled' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Value 0 -Force

    # Suppress feedback prompts and evaluation popups
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Siuf\Rules' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Siuf\Rules' -Name 'NumberOfSIUInPeriod' -Value 0 -Force

    # Disable GameDVR background app capture for new profiles
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0 -Force
    New-Item -Path 'Registry::HKU\DefaultUser\System\GameConfigStore' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -Force

    # Force garbage collection before unmounting the registry hive
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    reg unload 'HKU\DefaultUser' 2>&1 | Out-Null
}

# =========================================================================================
# SECTION 13: POWER POLICY & NETWORK PROFILE ENFORCEMENT
# =========================================================================================

# Enforce Private Network Profile category to permit local administrative management
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

# Duplicate and activate the hidden native Ultimate Performance power plan
$UltimateGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
powercfg -duplicatescheme $UltimateGuid 1>nul 2>nul
powercfg -setactive $UltimateGuid 1>nul 2>nul

# Set display timeout to 30 minutes on AC/DC
powercfg -change -monitor-timeout-ac 30 1>nul 2>nul
powercfg -change -monitor-timeout-dc 30 1>nul 2>nul

# Set Power Button Action to Hibernate (2) and Sleep Button Action to Sleep (1)
powercfg -setacvalueindex SCHEME_CURRENT SUB_BUTTONS PBTNACT 2 1>nul 2>nul
powercfg -setdcvalueindex SCHEME_CURRENT SUB_BUTTONS PBTNACT 2 1>nul 2>nul
powercfg -setacvalueindex SCHEME_CURRENT SUB_BUTTONS SBTNACT 1 1>nul 2>nul
powercfg -setdcvalueindex SCHEME_CURRENT SUB_BUTTONS SBTNACT 1 1>nul 2>nul
powercfg -SetActive SCHEME_CURRENT 1>nul 2>nul

# =========================================================================================
# SECTION 14: ACCESSIBILITY, ACTIVE USER AUDIO & BITLOCKER POLICY
# =========================================================================================

# Disable StickyKeys popup triggers
Set-ItemProperty -Path 'HKCU:\Control Panel\Accessibility\StickyKeys' -Name 'Flags' -Value '506' -Force

# Disable Spatial Audio in the active current user registry context
New-Item -Path 'HKCU:\Software\Microsoft\Multimedia\Audio' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Multimedia\Audio' -Name 'DisableSpatial' -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Multimedia\Audio' -Name 'SpatialSoundEnabled' -Value 0 -Force -ErrorAction SilentlyContinue

# Prevent automatic BitLocker hardware encryption on non-domain endpoints
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\BitLocker' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\BitLocker' -Name 'PreventDeviceEncryption' -Value 1 -Force

# Ensure Storage Service (StorSvc) is active
Set-Service -Name 'StorSvc' -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name 'StorSvc' -ErrorAction SilentlyContinue

# =========================================================================================
# SECTION 15: ENTERPRISE BROWSER POLICIES (MICROSOFT EDGE & BRAVE)
# =========================================================================================

# Enforce Microsoft Edge performance and privacy policies
$edgePolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
New-Item -Path $edgePolicyPath -Force | Out-Null
Set-ItemProperty -Path $edgePolicyPath -Name 'BackgroundModeEnabled' -Value 0 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'ParallelDownloadingEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'GpuRasterizationEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'Accelerated2dCanvasEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'BackForwardCacheEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'ShowRecommendationsEnabled' -Value 0 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'SpotlightExperienceEnabled' -Value 0 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'SleepingTabsEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'SleepingTabsTimeout' -Value 300 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'AutoDiscardSleepingTabsEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'SmartScreenEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'PreventSmartScreenPromptOverride' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'PreventSmartScreenPromptOverrideForFiles' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'PerformanceDetectorEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'ExtensionsPerformanceDetectorEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'RAMResourceControlsEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'EfficiencyModeEnabled' -Value 1 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'AIGenThemesEnabled' -Value 0 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'EdgeThemeEnabled' -Value 0 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'AllowGamesMenu' -Value 0 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'AllowSurfGame' -Value 0 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'HubsSidebarEnabled' -Value 0 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'EdgeOpenInSidebarEnabled' -Value 0 -Force
Set-ItemProperty -Path $edgePolicyPath -Name 'EdgeShoppingAssistantEnabled' -Value 0 -Force

# Enforce Brave Browser enterprise telemetry and web3 feature blocks
$bravePolicyPath = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'
New-Item -Path $bravePolicyPath -Force | Out-Null
Set-ItemProperty -Path $bravePolicyPath -Name 'BraveWalletDisabled' -Value 1 -Force
Set-ItemProperty -Path $bravePolicyPath -Name 'BraveRewardsDisabled' -Value 1 -Force
Set-ItemProperty -Path $bravePolicyPath -Name 'BraveVpnDisabled' -Value 1 -Force
Set-ItemProperty -Path $bravePolicyPath -Name 'AIInteractionsEnabled' -Value 0 -Force

# =========================================================================================
# SECTION 16: CORE SECURITY, HARDWARE ISOLATION & DEFENDER ASR RULES
# =========================================================================================

# Enforce LSASS Protected Process Light (RunAsPPL) and SmartScreen mode
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'RunAsPPL' -Value 1 -Force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableSmartScreen' -Value 2 -Force

# Enforce Virtualization-Based Security (VBS) and Hypervisor-Enforced Code Integrity (HVCI)
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -Value 1 -Force

New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -Value 1 -Force

New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Name 'Enabled' -Value 1 -Force

# Enforce Defender Attack Surface Reduction (ASR) rules:
#   BE9BA2D9-53EA-4CDC-84e5-9b1eeee46550 : Block executable content from email client and webmail
#   9e6c4e1f-7d60-472f-ba1a-a39af6b9414d : Block LSASS credential stealing
#   D4E3A620-D21D-47D5-892B-37D128292256 : Block Office applications from creating child processes
#   D1E1244A-4A57-4D34-828B-2C679F530723 : Block process creations originating from PsExec and WMI commands
Set-MpPreference -EnableControlledFolderAccess Enabled `
    -AttackSurfaceReductionRules_Ids 'BE9BA2D9-53EA-4CDC-84e5-9b1eeee46550', '9e6c4e1f-7d60-472f-ba1a-a39af6b9414d', 'D4E3A620-D21D-47D5-892B-37D128292256', 'D1E1244A-4A57-4D34-828B-2C679F530723' `
    -AttackSurfaceReductionRules_Actions Enabled -ErrorAction SilentlyContinue

Stop-Transcript -ErrorAction SilentlyContinue
