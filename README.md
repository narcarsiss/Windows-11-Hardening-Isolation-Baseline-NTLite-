# 🛡️ Windows 11 Hardening, Isolation, and Security Baseline (NTLite / Unattend)

This repository provides an enterprise-grade, production-verified unattended installation script (`autounattend.xml`) designed to deploy hardened, clean, and optimized Windows 11 endpoints. It automates out-of-box experience (OOBE) bypasses, applies strict security baselines, strips out consumer bloatware, enforces browser management policies, and optimizes system power and networking profiles.

---

## 📑 Table of Contents

1. [⚡ Power Management Configuration](https://www.google.com/search?q=%231-power-management-configuration)
2. [🌐 Network Optimizations & TCP Stack](https://www.google.com/search?q=%232-network-optimizations--tcp-stack)
3. [🌐 Microsoft Edge Enterprise Policies](https://www.google.com/search?q=%233-microsoft-edge-enterprise-policies)
4. [🦁 Brave Browser Enterprise Policies](https://www.google.com/search?q=%234-brave-browser-enterprise-policies)
5. [🔒 Core Security & Memory Hardening (VBS, LSA, ASR)](https://www.google.com/search?q=%235-core-security--memory-hardening-vbs-lsa-asr)
6. [🕵️‍♂️ Telemetry, Privacy & Bloatware Removal](https://www.google.com/search?q=%236-telemetry-privacy--bloatware-removal)
7. [💻 User Experience & Default Profile Tweaks](https://www.google.com/search?q=%237-user-experience--default-profile-tweaks)

---

## ⚡ 1. Power Management Configuration

The script modifies system power states to favor energy conservation and fast resumption while maintaining predictable physical button behaviors.

### Power Button Action

* **Current Setting:** Hibernate (AC: `2`, DC: `2`)
* **Description:** Pressing the physical power button places the system into hibernation (saving state to disk and cutting all power), rather than performing a full shutdown or instant sleep.

Possible settings:

* `=0` (Do nothing)
* `=1` (Sleep / S3 or Modern Standby)
* `=2` (Hibernate) — *Recommended for preserving open work across mobile/desktop sessions without battery drain.*
* `=3` (Shut down)

### Sleep Button / Lid Action

* **Current Setting:** Sleep (AC: `1`, DC: `1`)
* **Description:** Pressing the dedicated sleep button (or closing the laptop lid) triggers standard sleep mode.

Possible settings:

* `=0` (Do nothing)
* `=1` (Sleep) — *Recommended for quick wake times.*
* `=2` (Hibernate)
* `=3` (Shut down)

---

## 🌐 2. Network Optimizations & TCP Stack

### TCP Auto-Tuning Level

* **Current Setting:** `normal`
* **Description:** Windows 11’s TCP Auto-Tuning adjusts network buffer sizes automatically to improve download and connection performance.

Possible settings:

* `=disabled` — Disables auto-tuning; fixes compatibility with certain older routers or restrictive VPNs, but severely limits throughput on high-speed/high-latency connections.
* `=highlyrestricted` — Restricts buffer growth to a restricted range below the default window size.
* `=restricted` — Restricts TCP window growth past a predetermined scope.
* `=normal` — *Recommended for typical systems.* Allows optimal scaling for standard broadband and enterprise networks.
* `=experimental` — Uses aggressive scaling algorithms for testing environments.

### Receive Side Scaling (RSS)

* **Current Setting:** `enabled`
* **Description:** Distributes network receive processing across multiple CPU cores to improve network throughput and lower CPU bottlenecks on multi-core hardware.

Possible settings:

* `=enabled` — *Recommended.* Enhances multi-core CPU efficiency during heavy network loads.
* `=disabled` — Forces all network packet processing onto a single CPU core. Only used for troubleshooting specific legacy network card driver bugs.

---

## 🌐 3. Microsoft Edge Enterprise Policies

The deployment applies machine-wide configuration policies (`HKLM:\SOFTWARE\Policies\Microsoft\Edge`) to lock down resource usage, enhance security, and strip out unnecessary consumer features, games, and AI integrations.

### Sleeping Tabs

* **Current Setting:** Enabled with a 5-minute timeout (`SleepingTabsEnabled` = `1`, `SleepingTabsTimeout` = `300`, `AutoDiscardSleepingTabsEnabled` = `1`)
* **Description:** Automatically puts inactive background tabs to sleep after 5 minutes of non-use to conserve RAM and CPU cycles.

Possible settings:

* `=0` — Disabled; background tabs remain active continuously.
* `=1` — Enabled with customizable timeout parameters — *Recommended for performance.*

### SmartScreen & Security Overrides

* **Current Setting:** Strict enforcement (`SmartScreenEnabled` = `1`, `PreventSmartScreenPromptOverride` = `1`, `PreventSmartScreenPromptOverrideForFiles` = `1`)
* **Description:** Enforces Microsoft Defender SmartScreen protection and blocks users from bypassing warnings when attempting to download unverified or malicious files.

Possible settings:

* `=0` — SmartScreen disabled entirely (Not recommended).
* `=1` — Enabled with prompt overrides allowed for end users.
* `Strict (1 + Prevent Override)` — *Recommended for hardened environments.* Prevents users from overriding security blocks.

### Performance & Efficiency Modes

* **Current Setting:** Fully Enabled (`PerformanceDetectorEnabled`, `ExtensionsPerformanceDetector` , `RAMResourceControlsEnabled`, `EfficiencyModeEnabled` = `1`)
* **Description:** Enables automatic resource controls, efficiency mode for background tabs, and performance monitors to optimize hardware allocation.

### Feature & AI Restrictions

* **Current Setting:** Disabled (`AIGenThemesEnabled`, `EdgeThemeEnabled`, `AllowGamesMenu`, `AllowSurfGame`, `HubsSidebarEnabled`, `EdgeOpenInSidebarEnabled`, `EdgeShoppingAssistantEnabled` = `0`)
* **Description:** Strips out AI theme generators, built-in mini-games (Surf game), the right-hand sidebar, web-opening side panels, and built-in shopping assistants.

---

## 🦁 4. Brave Browser Enterprise Policies

If Brave is installed or deployed, enterprise policies (`HKLM:\SOFTWARE\Policies\BraveSoftware\Brave`) restrict built-in promotional and cryptographic features.

### Built-in Web3 & Crypto Features

* **Current Setting:** Disabled (`BraveWalletDisabled`, `BraveRewardsDisabled`, `BraveVpnDisabled`, `AIInteractionsEnabled` = `1` / `0`)
* **Description:** Disables built-in crypto wallets, Brave Rewards popups, integrated VPN services, and native AI chat assistants across the browser installation.

---

## 🔒 5. Core Security & Memory Hardening (VBS, LSA, ASR)

### LSA Protection (RunAsPPL)

* **Current Setting:** Enabled (`RunAsPPL` = `1`)
* **Description:** Runs the Local Security Authority Subsystem Service (LSASS) as a Protected Process Light (PPL), preventing unauthorized memory injection and credential-dumping tools (such as Mimikatz).

Possible settings:

* `=0` — Standard user-space process (vulnerable to credential theft).
* `=1` — Enabled as Protected Process Light — *Recommended.*
* `=2` — Enabled with UEFI audit mode.

### Virtualization-Based Security (VBS) & HVCI

* **Current Setting:** Enabled (`EnableVirtualizationBasedSecurity` = `1`, `Enabled` = `1` for Hypervisor-Enforced Code Integrity)
* **Description:** Uses hardware virtualization to create a secure memory region, protecting core operating system components from kernel-level rootkits and exploits.

### Attack Surface Reduction (ASR) & Controlled Folder Access

* **Current Setting:** Configured via `Set-MpPreference`
* **Description:** Enables Controlled Folder Access to block unauthorized apps from modifying protected user directories, alongside strict ASR rules targeting high-risk executable behaviors.

---

## 🕵️‍♂️ 6. Telemetry, Privacy & Bloatware Removal

* **Telemetry Level:** Restricted to minimum enterprise compliance (`AllowTelemetry` = `0`).
* **Consumer Features:** Suppresses pre-installed sponsored applications, cloud-optimized content, consumer account states, and Windows tips (`DisableWindowsConsumerFeatures` = `1`).
* **Cortana & Windows Search:** Fully disabled cloud search integration and Cortana hooks.
* **GameDVR & GameBar:** Strips background recording hooks, disables GameBar presence writers, and blocks background capture tasks service-wide.
* **Find My Device:** Disabled location tracking policies for endpoint deployment.

---

## 💻 7. User Experience & Default Profile Tweaks

All changes applied via the **Default User Registry Hive (`NTUSER.DAT`)** ensure that every new user account created on the machine inherits a clean, consistent baseline:

* **Taskbar Alignment & Grouping:** Configures taskbar button behavior and alignment preferences.
* **File Name Extensions:** Unhides known file extensions (`HideFileExt` = `0`) to prevent file-masquerading malware vectors.
* **Recycle Bin Desktop Icon:** Automatically displays the Recycle Bin icon on fresh desktop loads.
* **Notification Tray:** Disables auto-hiding notification icon behaviors to ensure visibility of critical system utilities.

## 🛡️ Functional Priorities
This config safely maintains the operating hooks for:
* **Windows Update:** Fully supported; staging layers left unmodified.
* **Modern Gaming:** Preserves Xbox framework layers, identity verification, and GPU profiling pipelines.
* **Hardware Interfacing:** Keeps native Bluetooth and Wi-Fi stacks alive.
* **Ecosystem Sync:** Phone Link framework dependencies remain completely intact.

## 🚀 Deployment Instructions
1. Open **NTLite** and mount your master Windows 11 base ISO.
2. Go to **Registry**, choose **Add -> File**, and import `registry/hardening_and_telemetry.reg`.
3. Go to **Post-Setup**, select **Add -> Command / Script**, reference `scripts/PostSetup-Machine.ps1`, and ensure its execution mode is set to **Machine-Independent**.
4. Integrate critical operating updates under the **Updates** panel before initiating the compile step.
