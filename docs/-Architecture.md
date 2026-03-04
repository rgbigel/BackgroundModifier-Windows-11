# Background4Logon+Desktop – Architecture (Version 4.000)

## Overview
Background4Logon+Desktop v4.000 is a deterministic, fully PowerShell‑based
pipeline that generates a unified background image for both the Windows
logon screen and the desktop. It encodes system identity, OS information,
and runtime metadata directly onto the background image.

The architecture is intentionally minimal, modular, and Git‑friendly.

---

## Pipeline Overview

### 1. BootIdentity.ps1
- Computes the active ESP identity using WMI/CIM.
- Builds a structured snapshot (`current.json`) with four domains:
  - **OS** – Windows version, build, edition, update level.
  - **System** – Host name, user, boot/logon times, IP address.
  - **ESP** – Deterministic ESP identity (Disk/Partition/Label/GUID).
  - **Meta** – Script version, timestamp, PowerShell version.
- Logging always on.
- Debug output via `-d` or `-debug`.

### 2. BackgroundRenderer.ps1
- Loads the snapshot.
- Renders only the required on‑screen fields:
  - OS UpdateVersion  
  - Host Name  
  - User  
  - Boot  
  - Logon  
  - Indexing  
  - IP Address  
- Draws text onto the base image (`LockBase.jpg`).
- Saves the final image as `LogonScreen.jpg`.

### 3. BackgroundStateMgr.psm1
- Applies the rendered image as the **desktop wallpaper**.
- Uses `SystemParametersInfo` via P/Invoke.
- Logging always on.

### 4. BackgroundNoBlurReg.psm1
- Enforces registry settings to disable Windows logon blur.
- Ensures the lock screen displays the rendered image crisply.

### 5. BackgroundSetter.ps1
- Orchestrates the entire pipeline.
- Calls all components in sequence.
- Logging always on; debug via `-d`.

### 6. BackgroundSetterStart.ps1
- Runs the pipeline immediately.
- Registers a scheduled task to run it at every logon.

---

## Directory Structure

src/ BootIdentity.ps1 BackgroundRenderer.ps1 BackgroundSetter.ps1 BackgroundSetterStart.ps1
modules/ BackgroundStateMgr.psm1 BackgroundNoBlurReg.psm1
assets/ LockBase.jpg
docs/ Architecture.md SnapshotSchema.md Changelog.md

Runtime directory (not in Git):
C:\BackgroundMotives
current.json LogonScreen.jpg *.log

---

## Design Principles

### Deterministic
- No drive letter assignment.
- No raw disk access.
- ESP detection based solely on WMI/CIM (`SystemVolume=True` + FAT32).

### Minimal
- Only two modules.
- No hooks.
- No BootDiskResolver.
- No optional logging flags.

### Debuggable
- Logs always written.
- Debug output enabled via `-d` or `-debug`.

### Git‑Friendly
- Clean separation of source, modules, assets, and docs.
- No runtime artifacts in the repository.

---

## Future Migration
The v4.000 snapshot schema is intentionally structured for:
- Python dataclasses  
- C# POCOs

