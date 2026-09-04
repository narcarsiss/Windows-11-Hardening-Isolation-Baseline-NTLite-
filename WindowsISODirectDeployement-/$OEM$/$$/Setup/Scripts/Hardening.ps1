# =========================================================================================
# HARDENING, PERFORMANCE, RAM OPTIMIZATION & QOL BASELINE SCRIPT
# =========================================================================================

$LogFile = "$env:SystemDrive\Windows\Panther\HardeningAndOptimization.log"
Start-Transcript -Path $LogFile -Append -ErrorAction SilentlyContinue

$defaultAdminPass = 'AdminSecurePass2026!'
$defaultOpPass    = 'OperatorSecurePass2026!'

# Default Credentials Warning Prompt
[System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework') | Out-Null
[System.Windows.MessageBox]::Show(
    'SECURITY WARNING: This endpoint was deployed using default template passwords (AdminSecurePass2026! / OperatorSecurePass2026!). Please update them immediately before production use!',
    'Moosehead Studio - Default Credentials Detected',
    'OK',
    'Warning'
) | Out-Null

# Scheduled Task for Privileged Account Login Warning
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -Command "[System.Reflection.Assembly]::LoadWithPartialName(''PresentationFramework''); [System.Windows.MessageBox]::Show(''Warning: This is a privileged account. Changes made while signed in may affect all users and system security.`n`nAdministrative access only. Use this account only when required for approved system maintenance.`n`nDo not use this account for email, web browsing, or routine work.'', ''Moosehead Studio - High Privilege Security Warning'', ''OK'', ''Warning'')"'
$trigger = New-ScheduledTaskTrigger -AtLogOn -User 'Administrator'
$settings = New-ScheduledTaskSettingsOption -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName 'AdminLoginSecurityWarning' -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force | Out-Null

# OEM Information & Branding
$oemPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'
New-Item -Path $oemPath -Force | Out-Null
Set-ItemProperty -Path $oemPath -Name 'Manufacturer' -Value 'Moosehead Studio' -Force
Set-ItemProperty -Path $oemPath -Name 'Model' -Value 'Hardened Windows 11 Endpoint' -Force
Set-ItemProperty -Path $oemPath -Name 'SupportURL' -Value 'https://github.com/narcarsiss/Windows-11-Hardening-Isolation-Baseline-NTLite-' -Force
Set-ItemProperty -Path $oemPath -Name 'Appreciation' -Value 'Thank you for using our security endpoint config' -Force

# Telemetry, Consumer Features & Bloatware Removal
reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v 'OemPreInstalledAppsEnabled' /t REG_DWORD /d '0' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' /v 'DisableWindowsConsumerFeatures' /t REG_DWORD /d '1' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start' /v 'ConfigureStartPins' /t REG_SZ /d '{"pinnedList": [{}]}' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' /v 'DisableConsumerAccountStateContent' /t REG_DWORD /d '1' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' /v 'DisableCloudOptimizedContent' /t REG_DWORD /d '1' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' /v 'EnableFeeds' /t REG_DWORD /d '0' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'AllowCortana' /t REG_DWORD /d '0' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Teams' /v 'DisableInstallation' /t REG_DWORD /d '1' /f 2>&1 | Out-Null
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v 'AllowTelemetry' /t REG_DWORD /d '0' /f 2>&1 | Out-Null
reg add 'HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice' /v 'Start' /t REG_DWORD /d '4' /f 2>&1 | Out-Null
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' -Name 'AllowFindMyDevice' -Value 0 -Force

# AI, Copilot, Recall & Widgets Isolation
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableRecallDataProviders' -Value 1 -Force
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value 1 -Force
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value 1 -Force
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowWidgets' -Value 0 -Force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Value 0 -Force

# Network Protocol & Bandwidth Optimization (LLMNR, SMB3, DoH, Throttling)
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -Name 'EnableMulticast' -Value 0 -Force
Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | Disable-NetAdapterBinding -ErrorAction SilentlyContinue
Disable-WindowsOptionalFeature -Online -FeatureName 'SMB1Protocol' -NoRestart -ErrorAction SilentlyContinue | Out-Null
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force -ErrorAction SilentlyContinue
Set-SmbClientConfiguration -RequireSecuritySignature $true -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Value 0xFFFFFFFF -Force
netsh int tcp set global autotuninglevel=normal 1>nul 2>nul
netsh int tcp set global rss=enabled 1>nul 2>nul

# Windows Update Driver Search & Metadata
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching' -Name 'DontSearchWindowsUpdate' -Value 0 -Force
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions' -Name 'PreventDeviceMetadataFromNetwork' -Value 1 -Force

# GameDVR & GameBar Neutralization
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR' /v 'AllowGameDVR' /t REG_DWORD /d '0' /f 2>&1 | Out-Null
reg add 'HKLM\SYSTEM\CurrentControlSet\Services\BcastDVRUserService' /v 'Start' /t REG_DWORD /d '4' /f 2>&1 | Out-Null
reg add 'HKLM\SYSTEM\CurrentControlSet\Services\GameBarPresenceWriter' /v 'Start' /t REG_DWORD /d '4' /f 2>&1 | Out-Null

# System Performance, Latency & Storage Optimizations
Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue | Out-Null
Set-Service -Name 'SysMain' -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name 'SysMain' -Force -ErrorAction SilentlyContinue
bcdedit /set dynamictick no 1>nul 2>nul

# Enable Hardware-Accelerated GPU Scheduling (HAGS)
$HagsPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
if (-not (Test-Path $HagsPath)) { New-Item -Path $HagsPath -Force | Out-Null }
Set-ItemProperty -Path $HagsPath -Name 'HwSchMode' -Value 2 -Force

# Disable NTFS Last Access Timestamp Writes
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'NtfsDisableLastAccessUpdate' -Value 1 -Force

# Disable Fast Startup (Forces Clean Driver Reloads and Eliminates Memory Leaks)
$SessionPowerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
if (-not (Test-Path $SessionPowerPath)) { New-Item -Path $SessionPowerPath -Force | Out-Null }
Set-ItemProperty -Path $SessionPowerPath -Name 'HiberbootEnabled' -Value 0 -Force

# Storage Sense Automation Policies (Weekly/Monthly Stale Temp and Log Cleanup)
$StorageSensePath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense'
if (-not (Test-Path $StorageSensePath)) { New-Item -Path $StorageSensePath -Force | Out-Null }
Set-ItemProperty -Path $StorageSensePath -Name 'AllowStorageSenseGlobal' -Value 1 -Force
Set-ItemProperty -Path $StorageSensePath -Name 'ConfigStorageSenseCloudContentCleanThreshold' -Value 30 -Force

# System-Wide Audio & Protected Audio Processing
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio' -Name 'DisableProtectedAudioProcessing' -Value 1 -Force

# Disable AutoRun & AutoPlay Globally for All Removable Drives (USB / Media)
$ExplorerPolicyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
if (-not (Test-Path $ExplorerPolicyPath)) { New-Item -Path $ExplorerPolicyPath -Force | Out-Null }
Set-ItemProperty -Path $ExplorerPolicyPath -Name 'NoDriveTypeAutoRun' -Value 255 -Type DWord -Force
Set-ItemProperty -Path $ExplorerPolicyPath -Name 'NoAutorun' -Value 1 -Type DWord -Force

$WinExplorerPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
if (-not (Test-Path $WinExplorerPolicyPath)) { New-Item -Path $WinExplorerPolicyPath -Force | Out-Null }
Set-ItemProperty -Path $WinExplorerPolicyPath -Name 'NoAutoplayfornonVolume' -Value 1 -Type DWord -Force

# RAM Reduction: Dynamic Service Host Process Grouping Threshold
$TotalRamKB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB)
if ($TotalRamKB -gt 4194304) {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'SvcHostSplitThresholdInKB' -Value $TotalRamKB -Type DWord -Force
} else {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'SvcHostSplitThresholdInKB' -Value 3800000 -Type DWord -Force
}

# RAM Reduction: Disable NDU Driver (Fixes Non-Paged Pool Memory Leaks)
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu' -Name 'Start' -Value 4 -Force

# RAM Reduction: Disable Executive Kernel/Driver Paging
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'DisablePagingExecutive' -Value 1 -Force

# RAM Reduction: Disable Unused Background Services (Print Spooler explicitly preserved)
Set-Service -Name 'MapsBroker' -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name 'MapsBroker' -Force -ErrorAction SilentlyContinue
Set-Service -Name 'RetailDemo' -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name 'RetailDemo' -Force -ErrorAction SilentlyContinue
Set-Service -Name 'DiagTrack' -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name 'DiagTrack' -Force -ErrorAction SilentlyContinue

# Persistent 7-Day Bluetooth Stereo Monitor Payload Generation
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

$BtTaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$MonitorScriptPath`""
$BtTaskTrigger = New-ScheduledTaskTrigger -AtLogOn
$BtTaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $BtTaskName -Action $BtTaskAction -Trigger $BtTaskTrigger -Settings $BtTaskSettings -User "NT AUTHORITY\SYSTEM" -Force | Out-Null

# Default User Hive Modifications (New Profile Preferences, UI/UX Speed, Visual, Audio & AutoRun Optimizations)
$defaultUserHive = 'C:\Users\Default\NTUSER.DAT'
if (Test-Path $defaultUserHive) {
    reg load 'HKU\DefaultUser' $defaultUserHive 2>&1 | Out-Null
    
    # UI/UX Speed & Menu Responsiveness
    New-Item -Path 'Registry::HKU\DefaultUser\Control Panel\Desktop' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '20' -Force

    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarGlomLevel' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarDa' -Value 1 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LastActiveClick' -Value 1 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Value 1 -Force

    # Disable AutoRun in Default User Profile
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoDriveTypeAutoRun' -Value 255 -Force

    # Audio & Spatial Sound Preferences (Default User)
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Multimedia\Audio' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Multimedia\Audio' -Name 'SpatialSoundEnabled' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Multimedia\Audio' -Name 'DisableSpatial' -Value 1 -Force

    # Disable Transparency Effects
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0 -Force

    # Disable Search Box Suggestions & Bing Integration
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Search' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 0 -Force
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0 -Force

    # Disable Advertising ID & Targeted Tracking
    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 -Force

    New-Item -Path 'Registry::HKU\DefaultUser\Control Panel\NotifyIconSettings' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Control Panel\NotifyIconSettings' -Name 'EnableAutoTray' -Value 0 -Force

    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name '{645FF040-5081-101B-9F08-00AA002F954E}' -Value 0 -Force

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

    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Siuf\Rules' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Siuf\Rules' -Name 'NumberOfSIUInPeriod' -Value 0 -Force

    New-Item -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0 -Force
    New-Item -Path 'Registry::HKU\DefaultUser\System\GameConfigStore' -Force | Out-Null
    Set-ItemProperty -Path 'Registry::HKU\DefaultUser\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -Force

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    reg unload 'HKU\DefaultUser' 2>&1 | Out-Null
}

# Network Profile & Power Policy Enforcement (Ultimate Performance Scheme Injection)
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

$UltimateGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
powercfg -duplicatescheme $UltimateGuid 1>nul 2>nul
powercfg -setactive $UltimateGuid 1>nul 2>nul

powercfg -change -monitor-timeout-ac 30 1>nul 2>nul
powercfg -change -monitor-timeout-dc 30 1>nul 2>nul
powercfg -setacvalueindex SCHEME_CURRENT SUB_BUTTONS PBTNACT 2 1>nul 2>nul
powercfg -setdcvalueindex SCHEME_CURRENT SUB_BUTTONS PBTNACT 2 1>nul 2>nul
powercfg -setacvalueindex SCHEME_CURRENT SUB_BUTTONS SBTNACT 1 1>nul 2>nul
powercfg -setdcvalueindex SCHEME_CURRENT SUB_BUTTONS SBTNACT 1 1>nul 2>nul
powercfg -SetActive SCHEME_CURRENT 1>nul 2>nul

# Accessibility, Active Execution Audio Context & BitLocker
Set-ItemProperty -Path 'HKCU:\Control Panel\Accessibility\StickyKeys' -Name 'Flags' -Value '506' -Force
New-Item -Path 'HKCU:\Software\Microsoft\Multimedia\Audio' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Multimedia\Audio' -Name 'DisableSpatial' -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Multimedia\Audio' -Name 'SpatialSoundEnabled' -Value 0 -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\BitLocker' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\BitLocker' -Name 'PreventDeviceEncryption' -Value 1 -Force
Set-Service -Name 'StorSvc' -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name 'StorSvc' -ErrorAction SilentlyContinue

# Browser Policies (Edge & Brave)
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

$bravePolicyPath = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'
New-Item -Path $bravePolicyPath -Force | Out-Null
Set-ItemProperty -Path $bravePolicyPath -Name 'BraveWalletDisabled' -Value 1 -Force
Set-ItemProperty -Path $bravePolicyPath -Name 'BraveRewardsDisabled' -Value 1 -Force
Set-ItemProperty -Path $bravePolicyPath -Name 'BraveVpnDisabled' -Value 1 -Force
Set-ItemProperty -Path $bravePolicyPath -Name 'AIInteractionsEnabled' -Value 0 -Force

# Core Security, VBS, LSA PPL & Expanded ASR Rules
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'RunAsPPL' -Value 1 -Force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableSmartScreen' -Value 2 -Force

New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -Value 1 -Force

New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -Value 1 -Force

New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Name 'Enabled' -Value 1 -Force

Set-MpPreference -EnableControlledFolderAccess Enabled `
    -AttackSurfaceReductionRules_Ids 'BE9BA2D9-53EA-4CDC-84e5-9b1eeee46550', '9e6c4e1f-7d60-472f-ba1a-a39af6b9414d', 'D4E3A620-D21D-47D5-892B-37D128292256', 'D1E1244A-4A57-4D34-828B-2C679F530723' `
    -AttackSurfaceReductionRules_Actions Enabled -ErrorAction SilentlyContinue

Stop-Transcript -ErrorAction SilentlyContinue