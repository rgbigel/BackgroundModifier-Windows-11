## Architecture.md for review
# (predecessor:D:\OneDrive\Git_Repositories\PS\BackgroundModifier\docs Background4Logon+Desktop – Consolidated Architecture (Profile: Default)

Version: 5.000 (Consolidated)  
Runtime Profile: `default`  
Author: Rolf Bercht  

> “Background4Logon+Desktop v4.000 is a deterministic, fully PowerShell‑based pipeline that generates a unified background image for both the Windows logon screen and the desktop.”  
> “The solution avoids unreliable hacks, avoids persistent state files, and relies exclusively on explicit inputs, deterministic logic, and reproducible outputs.”

---

## 1. Goals and scope

**Primary goal:**  
Generate a unified, information‑rich background for **Windows logon** and **desktop**, encoding:

- OS version and update level  
- System identity and boot/logon times  
- Synthetic ESP identity  
- Runtime metadata (script versions, timestamps, PowerShell version)

**Key properties:**

- Deterministic, reproducible behavior  
- Clear separation of **source** vs. **runtime**  
- Git‑friendly, no runtime artifacts in the repo  
- Minimal, modular, tool‑based implementation  
- Explicit, documented entry points via symlinks

---

## 2. Directory layout

### 2.1 Source repository (Git)

Root:

- `D:\OneDrive\Git_Repositories\PS\BackgroundModifier\`

Structure:

- `Source\`
  - `BootIdentity.ps1`
  - `BackgroundRenderer.ps1`
  - `BackgroundSetter.ps1`
  - `BackgroundSetterStart.ps1` (logon autorun orchestrator)
- `Source\Modules\`
  - `BootTools.psm1` (synthetic ESP + boot identity)
  - `RenderTools.psm1`
  - `WallpaperTools.psm1`
  - `BackgroundStateMgr.psm1`
  - `BackgroundNoBlurReg.psm1`
  - `ConfigTools.psm1`
  - `LoggingTools.psm1`
  - `TimeTools.psm1`
  - `SystemTools.psm1`
  - `ValidationTools.psm1`
  - `ErrorTools.psm1`
  - `SchedulerTools.psm1`
  - `TaskTools.psm1`
  - (other `*Tools.psm1` as already present)
- `Install\`
  - `Setup.ps1` (installer, creates runtime + symlinks + tasks)
  - `Cleanup.ps1` (module verification + runtime cleanup)
  - `BackgroundInstallationVerifier.ps1`
- `Docs\`
  - `Architecture.md` (this document)
  - `SnapshotSchema.md`
  - `Changelog.md`

No runtime files (JSON, logs, rendered images) live in the repo.

---

### 2.2 Runtime layout

Root:

- `C:\BackgroundMotives\`

Contents:

- `assets\`
  - `DesktopBase.jpg`
  - `LogonBase.jpg`
- `rendered\`
  - `DesktopScreen.jpg`
  - `LogonScreen.jpg`
- `logs\`
  - `BootIdentity_*.log`
  - `Renderer_*.log`
  - `Setter_*.log`
  - `Verifier_*.log`
  - (per‑module logs, rotated/overwritten as defined)
- `SolutionCode\`
  - **symlinks only**, no real code:
    - `BootIdentity.ps1` → `Source\BootIdentity.ps1`
    - `BackgroundRenderer.ps1` → `Source\BackgroundRenderer.ps1`
    - `BackgroundSetter.ps1` → `Source\BackgroundSetter.ps1`
    - `BackgroundSetterStart.ps1` → `Source\BackgroundSetterStart.ps1`
    - `BackgroundInstallationVerifier.ps1` → `Install\BackgroundInstallationVerifier.ps1`
- `current.json`
  - Snapshot of OS/System/ESP/Meta domains, plus user/logon fields

Assets are **prerequisites**: the installer does **not** copy or create them; it only verifies presence and warns if missing.

---

## 3. Execution model

### 3.1 Phase 1 – System startup (SYSTEM context)

**Trigger:**  
Scheduled task: `Background4Logon+Desktop-BootIdentity`  
- Runs at **system startup**  
- Runs as **SYSTEM**  
- No user context, no rendering, no wallpaper setting

**Entry point:**  
- `C:\BackgroundMotives\SolutionCode\BootIdentity.ps1` (symlink)

**Responsibilities:**

1. **Collect boot‑time snapshot**  
   - Uses `BootTools.psm1`, `SystemTools.psm1`, `TimeTools.psm1`  
   - Computes synthetic ESP identity via WMI/CIM and filesystem metadata  
   - Populates `current.json` with four domains:  
     - **OS** – Windows version, build, edition, update level  
     - **System** – host name, boot time, IP address (no user yet)  
     - **ESP** – synthetic ESP ID (offset, size, UUID, hash)  
     - **Meta** – script version, timestamp, PowerShell version   

2. **Write `current.json`**  
   - Creates or overwrites `C:\BackgroundMotives\current.json`  
   - Uses `ConfigTools.psm1` for deterministic JSON I/O  
   - No user/logon fields yet

3. **Logging**  
   - Writes `BootIdentity_*.log` to `C:\BackgroundMotives\logs`  
   - Logging always on; debug via `-d` / `-debug`   

**Non‑responsibilities:**

- Does **not** render images  
- Does **not** set wallpaper  
- Does **not** touch registry  
- Does **not** depend on user identity

---

### 3.2 Phase 2 – User logon (user context)

**Trigger:**  
Scheduled task: `Background4Logon+Desktop-Autorun`  
- Runs at **user logon**  
- Runs as the **interactive user**  
- One task per user (or configured scope)

**Entry point:**  
- `C:\BackgroundMotives\SolutionCode\BackgroundSetterStart.ps1` (symlink)

**Responsibilities:**

1. **Load and enrich snapshot**  
   - Loads `current.json` via `ConfigTools.psm1`  
   - Adds/updates:
     - `System.UserName`
     - `System.LogonTime`
   - Optionally adds user‑specific metadata (profile, domain, etc.)

2. **Orchestrate pipeline**  
   `BackgroundSetterStart.ps1` calls, in order:

   1. `BackgroundSetter.ps1` (orchestrator)
      - Validates environment (assets present, JSON readable)
      - Calls:
        - `BackgroundRenderer.ps1`
        - `BackgroundStateMgr` (via module)
        - `BackgroundNoBlurReg` (via module)
      - Uses `LoggingTools.psm1`, `ValidationTools.psm1`, `ErrorTools.psm1`

   2. `BackgroundRenderer.ps1`
      - Loads enriched `current.json`
      - Renders overlay onto:
        - `DesktopBase.jpg` → `DesktopScreen.jpg`
        - `LogonBase.jpg` → `LogonScreen.jpg`
      - Uses `RenderTools.psm1`, `ImageTools.psm1`, `TimeTools.psm1`
      - Writes `Renderer_*.log`  
      > “Renders only the required on‑screen fields: OS UpdateVersion, Host Name, User, Boot, Logon, Indexing, IP Address.”   

   3. `BackgroundStateMgr.psm1`
      - Applies `DesktopScreen.jpg` as desktop wallpaper  
      - Uses `WallpaperTools.psm1` + P/Invoke (`SystemParametersInfo`)  
      - Writes `Setter_*.log`   

   4. `BackgroundNoBlurReg.psm1`
      - Enforces registry settings to disable Windows logon blur  
      - Ensures lock screen displays `LogonScreen.jpg` crisply   

3. **Logging and verification**  
   - All steps log to `C:\BackgroundMotives\logs`  
   - `BackgroundInstallationVerifier.ps1` can be run manually or via installer to validate:
     - tasks exist  
     - symlinks are correct  
     - assets are present  
     - JSON is valid  

**Non‑responsibilities:**

- Does **not** recompute ESP identity (that’s Phase 1)  
- Does **not** run as SYSTEM  
- Does **not** modify boot‑time fields in `current.json` (only user/logon fields)

---

## 4. Installer and cleanup

### 4.1 `Install\Setup.ps1`

**Responsibilities:**

1. **Verify source modules**  
   - Ensures all required `*Tools.psm1` exist in `Source\Modules\`

2. **Prepare runtime structure**  
   - Creates (if missing):
     - `C:\BackgroundMotives\`
     - `assets\`, `logs\`, `rendered\`, `SolutionCode\`
   - Does **not** copy or create assets  
   - Verifies:
     - `DesktopBase.jpg`
     - `LogonBase.jpg`  
     Warns if missing, continues installation.

3. **Create symlinks in `SolutionCode`**  
   - `BootIdentity.ps1` → `Source\BootIdentity.ps1`
   - `BackgroundRenderer.ps1` → `Source\BackgroundRenderer.ps1`
   - `BackgroundSetter.ps1` → `Source\BackgroundSetter.ps1`
   - `BackgroundSetterStart.ps1` → `Source\BackgroundSetterStart.ps1`
   - `BackgroundInstallationVerifier.ps1` → `Install\BackgroundInstallationVerifier.ps1`

4. **Create scheduled tasks**  
   - `Background4Logon+Desktop-BootIdentity` (system startup, SYSTEM, calls `BootIdentity.ps1`)  
   - `Background4Logon+Desktop-Autorun` (user logon, user, calls `BackgroundSetterStart.ps1`)  
   - Uses `SchedulerTools.psm1`, `TaskTools.psm1`

5. **Initialize `current.json`**  
   - Optionally runs `BootIdentity.ps1` once during install  
   - Ensures `current.json` exists and is valid JSON

---

### 4.2 `Install\Cleanup.ps1`

**Responsibilities:**

1. **Module verification and pruning**  
   - Verifies required modules in `Source\Modules\`  
   - Removes obsolete modules not in the authoritative list

2. **Runtime cleanup (safe scope)**  
   - Cleans `C:\BackgroundMotives\logs` (age‑based)  
   - Cleans `C:\BackgroundMotives\rendered` (stale outputs)  
   - Uses `CleanupTools.psm1`

**Non‑responsibilities:**

- Does **not** touch:
  - `C:\BackgroundMotives\assets\`  
  - `C:\BackgroundMotives\current.json`  
  - `C:\BackgroundMotives\SolutionCode\` (symlinks)  

---

## 5. Dependency graph

### 5.1 High‑level graph

```text
[Scheduled Task: BootIdentity (SYSTEM, startup)]
        |
        v
[SolutionCode\BootIdentity.ps1]  -->  [BootTools.psm1]
        |                                |
        |                                v
        +--> [ConfigTools.psm1] --> writes C:\BackgroundMotives\current.json
        |
        +--> [LoggingTools.psm1], [TimeTools.psm1], [SystemTools.psm1]

[Scheduled Task: Autorun (User, logon)]
        |
        v
[SolutionCode\BackgroundSetterStart.ps1]
        |
        v
[BackgroundSetter.ps1]
        |
        +--> [ConfigTools.psm1] (load/update current.json with user/logon)
        +--> [BackgroundRenderer.ps1]
        |         |
        |         +--> [RenderTools.psm1], [ImageTools.psm1], [TimeTools.psm1]
        |         +--> reads assets\, writes rendered\
        |
        +--> [BackgroundStateMgr.psm1] --> [WallpaperTools.psm1]
        |
        +--> [BackgroundNoBlurReg.psm1]
        |
        +--> [LoggingTools.psm1], [ValidationTools.psm1], [ErrorTools.psm1]
