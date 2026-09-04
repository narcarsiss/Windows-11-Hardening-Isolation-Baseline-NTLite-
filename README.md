# 🛡️ Windows 11 Enterprise Hardening, Isolation & Unattend Baseline

An enterprise-grade, production-verified unattended installation framework (`autounattend.xml`) and post-installation PowerShell orchestration engine (`Hardening.ps1`) designed to deploy hardened, low-latency, and bloatware-free Windows 11 endpoints.

This pipeline automates Out-of-Box Experience (OOBE) bypasses, applies Virtualization-Based Security (VBS) and Attack Surface Reduction (ASR) baselines, enforces enterprise browser policies, strips telemetry, and optimizes hardware performance for enterprise production environments.

---

## 📑 Table of Contents

1. [⚠️ Disclaimers, Licensing & Scope](https://www.google.com/search?q=%23-disclaimers-licensing--scope)
2. [🛠️ Architecture & Staging Topology](https://www.google.com/search?q=%23%EF%B8%8F-architecture--staging-topology)
3. [🛡️ Functional Priorities & Ecosystem Compatibility](https://www.google.com/search?q=%23%EF%B8%8F-functional-priorities--ecosystem-compatibility)
4. [📄 Unattend Engine (`autounattend.xml`) Analysis](https://www.google.com/search?q=%23-unattend-engine-autounattendxml-analysis)
5. [🔒 Post-Install Hardening Engine (`Hardening.ps1`) Analysis](https://www.google.com/search?q=%23-post-install-hardening-engine-hardeningps1-analysis)
    * [Power Architecture & Hardware Button Protection](https://www.google.com/search?q=%23power-architecture--hardware-button-protection)
    * [Network Stack, TCP Auto-Tuning & Delivery Optimization](https://www.google.com/search?q=%23network-stack-tcp-auto-tuning--delivery-optimization)
    * [Microsoft Edge Enterprise Policies](https://www.google.com/search?q=%23microsoft-edge-enterprise-policies)
    * [Brave Browser Enterprise Policies](https://www.google.com/search?q=%23brave-browser-enterprise-policies)
    * [Core Security, VBS, LSA & ASR Rules](https://www.google.com/search?q=%23core-security-vbs-lsa--asr-rules)
    * [RAM Footprint, SvcHost & Kernel Optimizations](https://www.google.com/search?q=%23ram-footprint-svchost--kernel-optimizations)
    * [Audio System & Self-Destructing Bluetooth Engine](https://www.google.com/search?q=%23audio-system--self-destructing-bluetooth-engine)
    * [Default User Profile (`NTUSER.DAT`) Pre-Configuration](https://www.google.com/search?q=%23default-user-profile-ntuserdat-pre-configuration)


6. [🛑 Intentionally Omitted & Preserved Configurations](https://www.google.com/search?q=%23-intentionally-omitted--preserved-configurations)
7. [🚀 Deployment Instructions](https://www.google.com/search?q=%23-deployment-instructions)

---

## ⚠️ Disclaimers, Licensing & Scope

### Operational Scale

This deployment framework is actively maintained in live production environments by Moosehead Studio, serving as the default endpoint baseline across approximately 20,000 client endpoints Australia-wide. It is proven effective across technical and creative workloads, including software development, game design, digital audio workstation (DAW) engineering, and general enterprise workstation environments.

### Non-Destructive System Architecture

Unlike aggressive community "debloating" scripts that forcibly remove core Windows Libraries, system binaries, or `.dll`/`.sys` files, this framework relies strictly on official Microsoft Registry keys, Group Policies, and native system APIs. Omitting destructive file deletions preserves core OS file integrity, ensures seamless cumulative Windows Update servicing paths, and prevents OS corruption if optional features are added later.

### Licensing & Support Model

* **License:** Custom orchestration logic and scripts are distributed under the Apache License 2.0. Standard Microsoft End User License Agreement (EULA) terms govern all underlying Windows 11 operating system files and utilities.
* **Support Model:** Community support is limited strictly to GitHub Issue Tracking and Pull Requests.
* **Testing Requirement:** Do not execute or test this framework on live production endpoints without prior validation inside a virtual testbed.

### Environment Exclusions

This framework is designed exclusively for physical workstation and laptop endpoints running Windows 11 Pro or Enterprise. It is **NOT** supported or designed for:

* Microsoft Azure Virtual Machines or cloud-init deployment templates.
* Docker containers or container host environments.
* Windows Server variants (Windows Server 2019, 2022, or 2025).

---

## 🛠️ Architecture & Staging Topology

```
[ Bootable USB Media ]
  ├── sources/
  │    └── $OEM$/
  │         └── $$ / Setup / Scripts /
  │                                  └── Hardening.ps1   ──(Copied during PE)──> C:\Windows\Setup\Scripts\Hardening.ps1
  └── autounattend.xml                                   ──(Parses during OOBE)─> Triggers Hardening.ps1 at First Logon

```

### Native `$OEM$` Payload Staging

To prevent XML schema parsing crashes (`0x80004005` / `0x8030000C`) caused by multi-line inline scripts in `autounattend.xml`, deployment logic is externalized into `Hardening.ps1`.

Place the script inside the installer directory structure:
`USB:\sources\$OEM$\$$\Setup\Scripts\Hardening.ps1`

Windows Setup automatically parses `$OEM$\$$\` during the `windowsPE` file-copy pass, staging `Hardening.ps1` to `%windir%\Setup\Scripts\Hardening.ps1` prior to system initialization.

---

## 🛡️ Functional Priorities & Ecosystem Compatibility

This baseline strips telemetry and consumer bloatware without breaking core operating system frameworks:

* **Windows Update:** Fully functional; staging layers, servicing stacks, and security patch channels remain intact.
* **Modern Gaming:** Preserves Xbox framework authentication, identity verification, and GPU profiling pipelines.
* **Hardware Interfacing:** Retains full Bluetooth audio profiles, Wi-Fi stacks, and printing capabilities (`Spooler` service preserved).
* **Ecosystem Sync:** Phone Link dependencies, smart card infrastructure, and biometrics remain fully operational.

---

## 📄 Unattend Engine (`autounattend.xml`) Analysis

The answer file handles disk setup, regional defaults, OOBE bypasses, and account generation.

| Unattend Pass | Element / Component | Configuration / Value | Purpose & Technical Function |
| --- | --- | --- | --- |
| **windowsPE** | `International-Core-WinPE` | `SystemLocale`: `en-AU`<br>

<br>`UserLocale`: `en-AU`<br>

<br>`InputLocale`: `0409:00000409` | Establishes Australian regional standards (`DD/MM/YYYY` date/currency formats) while locking keyboard layout to US English. |
| **windowsPE** | `Microsoft-Windows-Setup` | `ProductKey`: KMS Client<br>

<br>`AcceptEula`: `true` | Automates EULA acceptance and provisions ownership metadata under `Moosehead Studio`. |
| **specialize** | `Shell-Setup` | `ComputerName`: `*`<br>

<br>`TimeZone`: `UTC` | Sets clock to UTC and assigns randomized hostnames (`*`) to eliminate WMI naming collisions during reboot cycles. |
| **specialize** | `Deployment` | `RunSynchronousCommand` (1–15) | Neutralizes GameBar protocol handlers (`ms-gamebar`, `ms-gamebarservices`, `ms-gamingoverlay`), presence servers, and `xbgm` services via `reg.exe` before user profiles generate. |
| **oobeSystem** | `OOBE` | Privacy & Account Screens: `Hidden` | Bypasses all consumer OOBE screens, diagnostic telemetry agreements, network setup checks, and mandatory Microsoft Account creation. |
| **oobeSystem** | `AutoLogon` | `Username`: `Administrator`<br>

<br>`LogonCount`: `1` | Executes a single administrative auto-logon pass to run post-install scripts. |
| **oobeSystem** | `UserAccounts` | Local Accounts: `Administrator`<br>

<br>`Operator` | Provisions local `Administrator` and non-privileged standard `Operator` accounts with fallback template credentials. |
| **oobeSystem** | `FirstLogonCommands` | `SynchronousCommand Order 1` | Invokes `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Windows\Setup\Scripts\Hardening.ps1"`. |

---

## 🔒 Post-Install Hardening Engine (`Hardening.ps1`) Analysis

### Power Architecture & Hardware Button Protection

System power states favor instant resumption and work preservation while protecting endpoints against accidental shutdown events:

* **Power Button Action (`PBTNACT = 2`):** Configured to **Hibernate** across both AC and DC states. Pressing the physical power button on chassis front panels saves the working session state to disk rather than performing an abrupt shutdown, preserving un-saved work while maintaining a "power off" state for the user.
* **Sleep Button Action (`SBTNACT = 1`):** Pressing the sleep button (or closing a laptop lid) triggers standard **Sleep** mode.
* **Fast Startup Disablement (`HiberbootEnabled = 0`):** Completely deactivates Windows Fast Startup. This forces clean driver reloads on shutdown, eliminating a kernel driver memory leak inherent to fast startup architectures since 2012.
* **Ultimate Performance Scheme:** Unlocks and activates the native Ultimate Performance power scheme (`e9a42b02-d5df-448d-aa00-03f14749eb61`).

---

### Network Stack, TCP Auto-Tuning & Delivery Optimization

* **TCP Auto-Tuning (`autotuninglevel = normal`):** Adjusts network buffer sizes dynamically to optimize connection throughput across broadband and enterprise networks.
* **Receive Side Scaling (`rss = enabled`):** Distributes network receive processing across multiple CPU cores to eliminate single-core bottlenecks under heavy network load.
* **Protocol Hardening:** Disables LLMNR (`EnableMulticast = 0`) to block Responder NTLM relay attacks, unbinds IPv6 on active adapters, removes `SMB1Protocol`, and enforces mandatory SMB3 signing (`RequireSecuritySignature = $true`).
* **Delivery Optimization (`DODownloadMode = 0`):** Blocks local endpoints from participating in peer-to-peer Windows Update bandwidth uploading to external internet hosts.
* **Network Throttling:** Sets `NetworkThrottlingIndex = 0xFFFFFFFF` to remove packet processing caps during non-multimedia workloads.

---

### Microsoft Edge Enterprise Policies

Applied machine-wide under `HKLM:\SOFTWARE\Policies\Microsoft\Edge`:

* **Sleeping Tabs (`SleepingTabsEnabled = 1`, `SleepingTabsTimeout = 300`):** Forces inactive background tabs to sleep after 5 minutes to reclaim physical RAM and CPU cycles.
* **SmartScreen Protection (`SmartScreenEnabled = 1`, `PreventSmartScreenPromptOverride = 1`):** Enforces Defender SmartScreen and prevents end users from overriding security warnings on unverified or malicious files.
* **Performance & Memory Controls:** Enables `EfficiencyModeEnabled`, `RAMResourceControlsEnabled`, and blocks background process persistence (`BackgroundModeEnabled = 0`) upon browser exit.
* **Feature Restrictions:** Disables Copilot sidebars, AI theme generators, built-in mini-games (Surf game), shopping assistants, and recommendation feeds.

---

### Brave Browser Enterprise Policies

Applied machine-wide under `HKLM:\SOFTWARE\Policies\BraveSoftware\Brave`:

* **Web3 & Promotion Neutralization:** Disables built-in crypto wallets (`BraveWalletDisabled = 1`), Brave Rewards prompts (`BraveRewardsDisabled = 1`), integrated VPN services (`BraveVpnDisabled = 1`), and AI interaction overlays (`AIInteractionsEnabled = 0`).

---

### Core Security, VBS, LSA & ASR Rules

* **LSASS Protection (`RunAsPPL = 1`):** Enforces Local Security Authority Subsystem Service execution as a Protected Process Light, blocking unauthorized memory dumping tools like Mimikatz.
* **Virtualization-Based Security (VBS & HVCI):** Enables hardware virtualization memory protection (`EnableVirtualizationBasedSecurity = 1`) and Hypervisor-Enforced Code Integrity (`HVCI`) to block kernel-level rootkits.
* **Attack Surface Reduction (ASR) Rules:** Enforces Defender ASR rules via `Set-MpPreference`:
* `BE9BA2D9-53EA-4CDC-84e5-9b1eeee46550`: Block executable content from email clients.
* `9e6c4e1f-7d60-472f-ba1a-a39af6b9414d`: Block LSASS credential stealing.
* `D4E3A620-D21D-47D5-892B-37D128292256`: Block Office apps from spawning child processes.
* `D1E1244A-4A57-4D34-828B-2C679F530723`: Block process creations originating from PsExec and WMI.


* **Global AutoRun/AutoPlay Destruction:** Deactivates AutoRun and AutoPlay (`NoDriveTypeAutoRun = 255`, `NoAutorun = 1`, `NoAutoplayfornonVolume = 1`) across `HKLM` and `NTUSER.DAT` to block USB `autorun.inf` execution vectors without restricting file transfers.

---

### RAM Footprint, SvcHost & Kernel Optimizations

* **Dynamic Service Host Process Grouping:** Reads physical RAM via `Win32_ComputerSystem` and configures `SvcHostSplitThresholdInKB` dynamically to consolidate `svchost.exe` process instances, reducing idle memory usage by 400MB–800MB.
* **NDU Memory Leak Fix:** Disables the Network Data Usage (`Ndu`) service (`Start = 4`) to prevent unbounded non-paged pool RAM growth during high-bandwidth network transfers.
* **Executive Paging Lock (`DisablePagingExecutive = 1`):** Forces the Windows Kernel and drivers to run entirely in physical memory space rather than swapping to disk, maximizing system responsiveness.
* **Background Service Pruning:** Disables `MapsBroker` and `RetailDemo`. Completely stops and disables `DiagTrack` (Connected User Experiences and Telemetry). Retains `Spooler` for physical printing support.

---

### Audio System & Self-Destructing Bluetooth Engine

* **Audio Processing Restructuring:** Disables DRM Protected Audio Processing (`DisableProtectedAudioProcessing = 1`) to strip latent equalization matrices that cause audio cutout bugs on enterprise communication software (e.g., 3CX softphones).
* **Spatial Audio Disablement:** Sets `SpatialSoundEnabled = 0` and `DisableSpatial = 1` across active user, default user, and system hives.
* **Persistent 7-Day Bluetooth Monitor:** Writes `%windir%\System32\BluetoothStereoMonitor.ps1` and registers a `SYSTEM` logon task (`BluetoothStereoForceMonitor`). During the first 7 days post-deployment, the engine inspects paired Bluetooth hardware and forces the low-quality "Hands-Free Telephony" mic service (`{0000111e-0000-1000-8000-00805f9b34fb}`) off, locking hardware into high-definition A2DP Stereo mode. *(Note: Users requiring headset microphone functionality can re-enable the microphone service manually under Windows Sound Control Panel settings).*
* **Zero System Footprint:** Once the 7-day timer expires, the script automatically unregisters its task, purges its log references, and deletes its own script file.

---

### Default User Profile (`NTUSER.DAT`) Pre-Configuration

Mounts `C:\Users\Default\NTUSER.DAT` during setup so every newly provisioned user profile inherits these settings automatically:

* **UI Speed & Responsiveness:** Drops `MenuShowDelay` to `20ms` for instant menu opening and disables window transparency effects (`EnableTransparency = 0`) to lower GPU/VRAM overhead.
* **Explorer Preferences:** Unhides file extensions (`HideFileExt = 0`), sets launch location to "This PC" (`LaunchTo = 1`), and expands system notification tray icons (`EnableAutoTray = 0`).
* **Privacy & Ad Blocking:** Disables Bing Start menu search (`BingSearchEnabled = 0`), consumer advertising tracking IDs (`AdvertisingInfo\Enabled = 0`), and content delivery app auto-installers (`SilentInstalledAppsEnabled = 0`).

---

## 🛑 Intentionally Omitted & Preserved Configurations

The following configurations were intentionally omitted or preserved to avoid operational breakage:

* **MAC Address & Hostname Randomization:** Left **disabled**. Randomizing MAC addresses breaks static DHCP reservations and 802.1X network access control on hardwired enterprise endpoints.
* **Strict Cookie Isolation:** Left **disabled**. Enforcing strict cookie isolation causes web applications (such as Xero) to drop authentication sessions when links open in new tabs.
* **Clear Pagefile on Shutdown:** Left **disabled**. Clearing the virtual memory pagefile on shutdown introduces severe shutdown delays of up to 10 minutes per reboot.
* **Kernel DMA & Core Isolation:** Core Isolation remains **enabled** by default for security boundaries. *(Note: On specialized high-performance gaming or real-time simulation endpoints, disabling Core Isolation in Windows Security recovers a documented 5%–10% GPU/CPU overhead)*.
* **BitLocker (Full Disk Encryption):** Left **disabled by default** during automated setup due to potential multi-drive encryption routing bugs. Manual post-install enablement with a **Pre-Boot PIN** is recommended.

> **🔒 Enterprise Security Note: Pre-Boot PIN vs. USB Encryption Keys**
> Deploying BitLocker with an external USB encryption key (`.bek` file) leaves endpoints vulnerable to physical seizure. If an endpoint and its connected USB key are seized together, the drive decrypts automatically upon boot. Furthermore, physical USB keys do not provide plausible deniability under legal disclosure warrants. Enforcing a **Pre-Boot PIN** ensures encryption keys remain locked in the TPM and are never loaded into physical RAM until the secret PIN is typed.

---

## 🚀 Deployment Instructions

### Method 1: Bootable USB Deployment (Recommended)

1. Format a USB drive as FAT32/NTFS and create a bootable Windows 11 installer (via Rufus or Media Creation Tool).
2. Copy `autounattend.xml` directly to the root directory of the USB drive (`USB:\autounattend.xml`).
3. Create the `$OEM$` directory structure on the USB drive:
`USB:\sources\$OEM$\$$\Setup\Scripts\`
4. Place `Hardening.ps1` inside the `Scripts` directory (`USB:\sources\$OEM$\$$\Setup\Scripts\Hardening.ps1`).
5. Boot target endpoints from the USB media. Windows Setup will execute unattended and apply the baseline automatically.

### Method 2: NTLite Base ISO Compile

1. Mount your target Windows 11 ISO inside **NTLite**.
2. Under **Unattended**, import `autounattend.xml`.
3. Under **Post-Setup**, add `Hardening.ps1` with execution context set to **Machine-Independent**.
4. Apply critical cumulative updates under the **Updates** tab before initiating the compile build.

---
