## Requirements.md for review
# (historic predecessor:D:\OneDrive\Git_Repositories\PS\BackgroundModifier\docs Background4Logon+Desktop – Consolidated Implementation (Profile: Default)

Version: 5.000 (Consolidated)  
Runtime Profile: `default`  
Author: Rolf Bercht  

> “BackgroundModifier is a PowerShell‑based solution that generates background images for both the Windows logon screen and the desktop.”  
> “The solution Follows the defined Implementation, Methods, Styles and Rules given in this Document”

> "Notes about Review process: Requirements can include mandatory Implementation / Solution decisions"

---

## 1. Requirements and Scope

**Primary goal of the Requirements of the Solution:**  
Generate a unified, information‑rich background for **Windows logon** and **Desktop** background screens, encoding:

- OS version and update level  
- System identity and boot/logon times  
- Synthetic ESP/BCD/uEFI identity  
- Runtime metadata (script versions, timestamps, PowerShell version)

**Key Properties:**

- Deterministic, reproducible behavior  
- Clear separation of **source** vs. **runtime**  
- Git‑friendly, no runtime artifacts in the repo  
- Minimal, modular, tool‑based implementation 
- supports installation, debugging and logging 
- Explicit, documented entry points via symlinks for simplified user access to exposed functionality.

** Control Flow and Data Layout

The code is executed in two stages:

1. During System Startup (as an elevated Task)
2. After the user has logged on (via autoRun at logon)

- During system startup, the solution must determine the System Information, like OS Version, Update Level, EFI path used, volume Label of the EFI partition (which probably does not have a drive letter). 
	Should the volume label not be available, use the disk number 
	-- the information will be stored in the runtime Path (structure see below) in the file State.json
	-- the Task's executable code must be able to run in Powershell, and be self-elevating when needed, and be easy to debug
	-- the information sources for the State.json file is not fixed, except for the volume label of the EFI partition, which is derived via Diskpart-><pipe or tempfile>->(subsequently launched Solution code)
	-- State.json will be completed by the Solution code running in the Logon autoRun, the information in it must not be kept specific to the stage where it is run and must not be compromised by the "other" stage.
	-- the startup stage is responsible for checking prerequisite files, using the same rules as the Installation helper used to check successful Installation.
	-- the startup  stage must set the automatic run of the logon stage
	-- the startup stage must log any problems encountered with advice to the user to apply corrections, but try to run entirely	

The solution, in accordance with Requirements (Goals), is stored in a GIT repository named "BackgroundModifier"

The runtime data is contained in the directory structure `C:\BackgroundMotives\`

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
  - `BackgroundStateMgr.psm1` (implemented in Source\Modules)
  - `BackgroundNoBlurReg.psm1` (implemented in Source\Modules)
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
  - `Implementation.md` (this document; formerly Architecture.md and now refined as Implementation.md)
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
- `State.json`
  - Snapshot of OS/System/ESP/Meta domains, plus user/logon fields

Assets are **prerequisites**: the installer does **not** copy or create them; it only verifies presence and warns if missing.

---

## 3. Execution model

### 3.1 Phase 1 – System startup (SYSTEM context)

**Trigger:**  
Scheduled task: `BackgroundModifier-BootIdentity`  
- Runs at **system startup**  
- Runs as **SYSTEM**  
- No user context, no rendering, no wallpaper setting

**Entry point:**  
- `C:\BackgroundMotives\SolutionCode\BootIdentity.ps1` (symlink -> BootIdentity.ps1)

**Responsibilities:**

1. **Collect boot‑time snapshot**  
   - Initiated by Source\BootIdentity.ps1
   - Uses `BootTools.psm1`, `SystemTools.psm1`, `TimeTools.psm1`  
   - Computes synthetic ESP identity via WMI/CIM and filesystem metadata  
   - Populates `State.json` with four domains:  
     - **OS** – Windows version, build, edition, update level  
     - **System** – host name, boot time, IP address (no user yet)  
     - **ESP** – synthetic ESP ID (offset, size, UUID, hash)  
	 - **UserInfo** - ignored when present, dummy if new
     - **Meta** – script version, timestamp, PowerShell version   

2. **Write `State.json`**  
   - Creates, Updates and (partially) overwrites `C:\BackgroundMotives\State.json`  
   - Uses `ConfigTools.psm1` for deterministic JSON I/O  
   - No UserInfo fields yet, but unchanged if present
   - Contains the timestamp (precise) of the State.json file after update, field is named "LastRunInfo", stored in the "Meta" domain
   - Checks the timestamps of the .jpg files in the rendered\ directory and warns (via log) if they are later than the State.json timestamp. Note: these .jpg files may be missing at that time.

3. **Logging**  
   - Writes `BootIdentity_*.log` to `C:\BackgroundMotives\logs`  
   - Logging always on; debug via `-d` / `-debug
   - Trace mode, activated by -t flag. -t implies -d

**Non‑responsibilities:**

- Does **not** render images  
- Does **not** set wallpaper  
- Does **not** touch registry (except to set up the System and Logon started Tasks)  
- Does **not** depend on user identity or modify the json domains used by other runtime phases (e.G. UserInfo)

### ESP Detection (Diskpart-Based)

BootIdentity must identify all EFI System Partitions using Diskpart.

- Use two Diskpart calls (A1, variant 1):

  Call 1:
      list disk
      select disk <n>
      list partition

  Call 2:
      list volume

- Identify EFI partitions by their partition type GUID.
- Extract for each EFI partition:
  - DiskNumber
  - PartitionNumber
  - PartitionTypeGuid
  - VolumeLabel (may be blank for non-EFI volumes; EFI volumes have labels)
  - DriveLetter (may be blank)

- Correlate partitions from Call 1 with volumes from Call 2 using DiskNumber + PartitionNumber.
- Store all EFI partitions in State.json.
- Determine the active ESP by its volume label “System”.
- Other EFI partitions are labeled “Hidden”.
- Capture Diskpart output via pipeline, not temporary files.

### ESP Bootloader Identification

BootIdentity must determine the EFI bootloader file that was actually used for the current boot.

- The authoritative source is the active BCD entry.
- BootIdentity must query BCD (`bcdedit /enum {current}` or equivalent) and extract:
  - `device` (must match the active ESP)
  - `path` (relative EFI file path, e.g. `\EFI\Microsoft\Boot\bootmgfw.efi`)
- BootIdentity must combine:
  - the active ESP’s resolved volume path  
  - the BCD `path`  
  into a full filesystem path to the bootloader file.
- This full path must be written to `State.json` under:
  - `ESP.Active.BootLoaderPath`
- No raw BCD output is stored.
- If the BCD entry cannot be resolved, BootIdentity must log an error and continue writing the remaining ESP fields.


---

### 3.2 Phase 2 – User logon (user context)

**Trigger:**  
Scheduled task: `BackgroundModifier-Autorun`  
- Runs at **user logon**  
- Runs as the **interactive user**  
- One task per user (or configured scope)

**Entry point:**  
- `C:\BackgroundMotives\SolutionCode\BackgroundSetterStart.ps1` (symlink)

**Responsibilities:**

1. **Load and enrich snapshot**  
   - Validates environment (assets present, JSON readable)
      -- Uses `LoggingTools.psm1`, `ValidationTools.psm1`, `ErrorTools.psm1`
   - Obtains a timestamp from `State.json` as LastRunInfo, when `State.json` is missing, stops with error message (logged)
   - Loads `State.json` via `ConfigTools.psm1`  
   - Adds/updates the json Domain "UserInfo": 
     - `System.UserName`
     - `System.LogonTime`
   - Optionally adds user‑specific metadata into the UserInfo (profile, domain, etc.)
   - uses the timestamp from `State.json` (above)
   - waits by pausing/repeating (5) times until the timestamps of the files `DesktopScreen.jpg`and  `LogonScreen.jpg` have become >= LastRunInfo. When repeats do not succeed, issue error message and abort the pipeline.

2. **Orchestrate pipeline**  
   `BackgroundSetterStart.ps1` calls, in order:

   1. `BackgroundSetter.ps1` (orchestrator)
      - Calls:
        - `BackgroundRenderer.ps1`
        - `BackgroundStateMgr` (via module)
        - `BackgroundNoBlurReg` (via module)

   2. `BackgroundRenderer.ps1`
      - Loads `State.json` 
      - Renders overlay onto:
        - `DesktopBase.jpg` → `DesktopScreen.jpg`
        - `LogonBase.jpg` → `LogonScreen.jpg`
      - Uses `RenderTools.psm1`, `ImageTools.psm1`, `TimeTools.psm1`
      - Writes `Renderer_*.log`  
	  - Updates LastRunInfo
      > “Renders only the required on‑screen fields: OS UpdateVersion, Host Name, User, Boot, Logon, Indexing, IP Address.”   

   3. `BackgroundStateMgr.psm1`
      - Applies `DesktopScreen.jpg` as desktop wallpaper  
	  - Applies `LogonScreen.jpg` as Logon wallpaper  
		-- Note: "Apply" implies that the Screens are activated for the Session/System
      - Uses `WallpaperTools.psm1` + P/Invoke (`SystemParametersInfo`)  
      - Writes `Setter_*.log`   

   4. `BackgroundNoBlurReg.psm1`
      - Enforces registry settings to disable Windows logon blur  
		-- Ensures lock screen displays `LogonScreen.jpg` crisply  (using the data rendered into `State.json`)

3. **Logging and verification**  
   - All steps log to `C:\BackgroundMotives\logs`  
   - `BackgroundInstallationVerifier.ps1` can be run manually or via installer to validate:
     - tasks exist  
     - symlinks are correct  
     - assets are present  
     - JSON is valid  

**Non‑responsibilities:**

- Does **not** recompute ESP identity (that’s Phase 1, System, see Source\BootIdentity.ps1)  
- Does **not** run as SYSTEM  
- Does **not** modify boot‑time fields in `State.json` (only LastRunInfo like user/logon fields )

---

## 4. Installer and cleanup

### 4.1 `Install\Setup.ps1`

**Responsibilities:**

1. **Verify source modules**  
   - Ensures all required `*Tools.psm1` exist in `Source\Modules\`
   - Ensures all required `*.psm1` exist in `Source\` (or `Installation`, only when installation-Related)

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
   - `BackgroundModifier-BootIdentity` (system startup, SYSTEM, calls `BootIdentity.ps1`)  
   - `BackgroundModifier-Autorun` (user logon, user, calls `BackgroundSetterStart.ps1`)  
   - Uses `SchedulerTools.psm1`, `TaskTools.psm1`

5. **Initialize `State.json`**  
   - Optionally runs `BootIdentity.ps1` once during install  
   - Ensures `State.json` exists and is valid JSON
   - Does not alter data from (optional) earlier results of the components run after User-Logon

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
  - `C:\BackgroundMotives\State.json`  
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
        +--> [ConfigTools.psm1] --> writes C:\BackgroundMotives\State.json
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
        +--> [ConfigTools.psm1] (load/update State.json with user/logon)
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

### 5.2 Undocumented Infrastructure and Support Modules

** check this **

The following 10 modules exist in Source\Modules\ but are not explicitly documented in the dependency graph above.
They provide bootstrap support, infrastructure, and integration functions. Their architectural roles are defined below.

#### 5.2.1 Bootstrap and Command-Line Support

**SetFlagsTool.psm1** – Command-line flag parsing

- Parses runtime flags: -t (trace), -d (debug), -v (verbose)
- Used by all entry-point scripts (BootIdentity, BackgroundRenderer, BackgroundSetter, BackgroundSetterStart)
- Determines execution mode: normal, debug, or trace
- **Architectural Purpose:** Bootstrap; enables debuggability without code changes

**ModeTools.psm1** – Debug and trace mode management

- Manages the state of debug/trace mode flags across module lifecycle
- Enforces mode invariants (trace implies debug)
- Used by LoggingTools and output modules to alter verbosity
- **Architectural Purpose:** Cross-module mode coordination; centralized debug state

#### 5.2.2 Path and Environment Infrastructure

**Constants.psm1** – Global well-known paths and constants

- Provides definitions for:
  - C:\BackgroundMotives\ (runtime root)
  - C:\BackgroundMotives\logs\, 
endered\, ssets\, SolutionCode\
  - Expected asset file names: DesktopBase.jpg, LogonBase.jpg
  - Log file naming patterns
- Used by all modules requiring filesystem access
- **Architectural Purpose:** DRY principle; single source of truth for paths; facilitates portability

**PathTools.psm1** – Path validation and directory creation

- Validates directory existence and writability
- Creates missing directories with proper error handling
- Resolves relative/absolute paths
- Used by Setup.ps1 (directory creation), runtime scripts (validation)
- **Architectural Purpose:** Safe, idempotent filesystem operations; consistent error reporting

**ProfileTools.psm1** – User profile identification and access

- Retrieves current user's SID, profile path, registry hive location
- Used by UserInfo enrichment in Phase 2 (logon stage)
- Resolves user-specific paths for registry operations (logon blur settings)
- **Architectural Purpose:** User context isolation; profile-specific customization

#### 5.2.3 Installation and Task Management Support

**InstallerTools.psm1** – Setup.ps1 helper functions

- Provides utilities for:
  - Scheduled task creation/validation (complements TaskTools.psm1)
  - Symlink creation and validation
  - Module existence verification
  - Prerequisite checking (assets, runtime folders)
- Used by Install\Setup.ps1
- **Architectural Purpose:** Installation workflow support; cleanly separates installer logic from task COM wrapper code (TaskTools)

#### 5.2.4 Logging and Reporting Infrastructure

**Logging.psm1** – LEGACY (Archive)

- Legacy predecessor of LoggingTools.psm1
- ** check this ** – Archive or delete; use LoggingTools.psm1 exclusively
- **Action:** Verify no active code references Logging.psm1; move to archive/ folder

**TranscriptTools.psm1** – PowerShell transcript management

- Starts/stops/rotates PowerShell session transcripts
- Optional: used for comprehensive execution tracing (beyond LoggingTools)
- Writes transcript files to C:\BackgroundMotives\logs\transcripts\
- **Architectural Purpose:** Deep audit trail; supports compliance/debugging scenarios

**SummaryTools.psm1** – Execution summary and reporting

- Generates execution summaries: phase duration, modules loaded, errors encountered
- Used by orchestrators (BackgroundSetterStart, Setup) to report completion status
- Outputs to console and log file
- **Architectural Purpose:** User feedback; operational visibility

#### 5.2.5 Validation and Error Handling Support

**Validation.psm1** – LEGACY (Archive)

- Legacy predecessor of ValidationTools.psm1
- ** check this ** – Archive or delete; use ValidationTools.psm1 exclusively
- **Action:** Verify no active code references Validation.psm1; move to archive/ folder

---

## 6. Recommended Actions for Undocumented Modules

1. **Archive Legacy Modules:**
   - `Logging.psm1` – Legacy variant; archive or delete (use `LoggingTools.psm1` exclusively)
   - `Validation.psm1` – Legacy variant; archive or delete (use `ValidationTools.psm1` exclusively)

2. **Essential Infrastructure Modules (keep and document):**
   - Constants.psm1 – Add "Uses" statements to BootIdentity, BackgroundRenderer, Setup phases
   - SetFlagsTool.psm1 – Document as bootstrap (used by all entry points)
   - ModeTools.psm1 – Document as cross-module mode state coordinator

3. **Installation-Specific Modules (conditional keep):**
   - InstallerTools.psm1 – Keep if Setup.ps1 requires installation workflow support beyond TaskTools
   - PathTools.psm1 – Keep if used for runtime path operations; otherwise consolidate into Constants

4. **Optional/Reporting Modules (review scope):**
   - TranscriptTools.psm1 – Decide scope: required for compliance? Keep or archive
   - SummaryTools.psm1 – Decide scope: required for user feedback? Keep or archive
   - ProfileTools.psm1 – Verify if Phase 2 (UserInfo enrichment) requires profile path access

---

## 7. Versioning Policy

- Baseline release is `5.000`.
- Minor, non-breaking changes increment by `.001` (for example: `5.001`, `5.002`).
- Redesign-level changes increment by `.100` (for example: `5.100`, `5.200`).
- Module headers and documentation versions must be updated together with the repository version.
