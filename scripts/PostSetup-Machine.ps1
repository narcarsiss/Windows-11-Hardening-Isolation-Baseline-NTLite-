# Custom NTLite Post-Setup Script (Machine-Independent Stage)
# Objective: Aggressive Telemetry/Feature Stripping while preserving Core Hardware & Gaming

$ErrorActionPreference = "SilentlyContinue"
Write-Output "[*] Executing Windows 11 Hardening Pipeline..."

# Terminate & Disable Target Diagnostic Services
$ServicesToDisable = @("DiagTrack", "dmwappushservice", "WerSvc")
foreach ($Service in $ServicesToDisable) {
    if (Get-Service -Name $Service) {
        Stop-Service -Name $Service -Force
        Set-Service -Name $Service -StartupType Disabled
        Write-Output "[-] Disabled Service: $Service"
    }
}

# Infrastructure Sanity Verification (Ensure Essential Stacks Stay Online)
$ProtectedServices = @("wuauserv", "bthserv", "WlanSvc", "XboxGipSvc")
foreach ($Protected in $ProtectedServices) {
    if (Get-Service -Name $Protected) {
        Set-Service -Name $Protected -StartupType Automatic
    }
}

# Disable Core Scheduled Telemetry Tasks
$TargetTasks = @(
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Autochk\Proxy"
)
foreach ($Task in $TargetTasks) {
    Disable-ScheduledTask -TaskName ($Task -split '\\')[-] -TaskPath ($Task -replace '(.*\\)(.*)', '$1')
}

Write-Output "[+] Post-Setup Pipeline Completed Safely."
