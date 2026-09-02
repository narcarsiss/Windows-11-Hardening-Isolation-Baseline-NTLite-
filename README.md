# Windows 11 Hardening & Isolation Baseline for Client Endpoints + (NTLite fileStructure-Planned)

A granular, modular infrastructure baseline configured specifically to strip tracking systems and establish hardware exploit mitigation without breaking primary production tools.

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
