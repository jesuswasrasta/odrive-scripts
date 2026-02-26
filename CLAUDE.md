# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides automated installation and desktop integration for the odrive sync agent on Linux systems with KDE. It consists of an idempotent installer script plus supporting assets (desktop files, MIME types, icons, systemd service).

## Repository Structure

| File | Role |
|------|------|
| `install-odrive-linux.sh` | Main installer — orchestrates all installation steps |
| `odrive-sync-recursive.sh` | Helper script deployed to `~/.local/bin/`; syncs `.cloud`/`.cloudf` files recursively |
| `odrive.service` | systemd user service template |
| `odrive-mimetypes.xml` | MIME type definitions for `.cloud` and `.cloudf` extensions |
| `odriveSync-kde5.desktop` / `odriveSync-kde6.desktop` | Dolphin context menu for `.cloud`/`.cloudf` files |
| `odriveFolders-kde5.desktop` / `odriveFolders-kde6.desktop` | Dolphin context menu for regular directories (unsync action) |
| `odrive-file.desktop` / `odrive-folder.desktop` | File-type associations for `.cloud`/`.cloudf` |
| `odrive.desktop` | Main application launcher |

## Installation Script Architecture

`install-odrive-linux.sh` supports four modes:

```bash
./install-odrive-linux.sh           # Normal install (skip existing files)
./install-odrive-linux.sh --check   # Verify installation status (no changes)
./install-odrive-linux.sh --repair  # Reinstall only missing/broken components
./install-odrive-linux.sh --force   # Complete reinstall (overwrite everything)
```

The script runs **9 sequential steps**:

1. **odrive binaries** — downloads `odrive.py`, `odriveagent`, `odrive` to `~/.odrive-agent/bin/`
2. **Mount directory** — creates `~/odrive-agent-mount/`
3. **Icons** — installs `odrive-logo.png` as three names into `~/.local/share/icons/hicolor/256x256/mimetypes/`
4. **Desktop files** — copies `odrive.desktop`, `odrive-file.desktop`, `odrive-folder.desktop` to `~/.local/share/applications/`
5. **Recursive sync script** — copies `odrive-sync-recursive.sh` to `~/.local/bin/`
6. **MIME types** — copies `odrive-mimetypes.xml` to `~/.local/share/mime/packages/` and runs `update-mime-database`
7. **KDE service menus** — installs `odriveSync.desktop` and `odriveFolders.desktop` into the version-specific directory
8. **Desktop/KDE cache** — runs `update-desktop-database` and `kbuildsycoca5`/`kbuildsycoca6 --noincremental`
9. **systemd user service** — copies `odrive.service` to `~/.config/systemd/user/`, then optionally enables it

### KDE Version Detection (Step 7)

1. Parse `plasmashell --version` output
2. Fallback: check `/usr/share/kf6` vs `/usr/share/kf5` directories
3. If unknown: install both KDE5 and KDE6 variants

| KDE Version | Service menu directory |
|-------------|----------------------|
| KDE5 | `~/.local/share/kservices5/ServiceMenus/` |
| KDE6 | `~/.local/share/kio/servicemenus/` |

## Key Paths (Deployed)

| Purpose | Path |
|---------|------|
| odrive binaries | `~/.odrive-agent/bin/` |
| Mount point | `~/odrive-agent-mount/` |
| Desktop files | `~/.local/share/applications/` |
| MIME type icons | `~/.local/share/icons/hicolor/256x256/mimetypes/` |
| MIME definitions | `~/.local/share/mime/packages/` |
| Recursive sync helper | `~/.local/bin/odrive-sync-recursive.sh` |
| Systemd service | `~/.config/systemd/user/odrive.service` |
| odrive main log | `~/.odrive-agent/log/main.log` |
| Recursive sync log | `~/.odrive-agent/log/recursive-sync-debug.log` |

## Context Menu Actions

`odriveSync` desktop files (triggered on `.cloud`/`.cloudf` files) expose three actions:
- **odrive sync** — calls `odrive.py sync <file>`
- **odrive sync all (recursive)** — calls `odrive-sync-recursive.sh <path>`
- **odrive unsync** — calls `odrive.py unsync <file>`

`odriveFolders` desktop files (triggered on plain directories) expose:
- **odrive unsync** — calls `odrive.py unsync <dir>`

> **Known path issue:** The KDE6 `odriveSync` desktop file references `$HOME/.odrive-agent/bin/odrive-sync-recursive.sh`, but the installer deploys the script to `~/.local/bin/odrive-sync-recursive.sh`. If the recursive sync action doesn't work, check which path is referenced in the installed service menu file.

## Testing Commands

```bash
# Run in check mode (non-destructive)
./install-odrive-linux.sh --check

# Verify KDE service menus are installed
ls ~/.local/share/kio/servicemenus/        # KDE6
ls ~/.local/share/kservices5/ServiceMenus/ # KDE5

# Verify MIME types and desktop database
update-desktop-database ~/.local/share/applications/
update-mime-database ~/.local/share/mime/

# Check systemd service
systemctl --user status odrive.service
journalctl --user -u odrive.service

# Tail recursive sync debug log
tail -f ~/.odrive-agent/log/recursive-sync-debug.log
```

## Post-Installation Manual Steps

```bash
# 1. Authenticate
python ~/.odrive-agent/bin/odrive.py authenticate <auth-key>

# 2. Mount
python ~/.odrive-agent/bin/odrive.py mount ~/odrive-agent-mount /

# 3. Enable service (if not done during install)
systemctl --user enable --now odrive.service
```

## Dependencies

- `curl` — download odrive binaries
- `python` or `python3` — run odrive CLI
- KDE Plasma 5 or 6 — for context menu integration
- All asset files must be present in the same directory as the installer at runtime

## Related Resources

- odrive sync agent docs: https://docs.odrive.com/docs/odrive-sync-agent
- odrive forum CLI thread: https://forum.odrive.com/t/odrive-sync-agent-a-cli-scriptable-interface-for-odrives-progressive-sync-engine-for-linux-os-x-and-windows/499/13
- Advanced Python utilities: https://github.com/amagliul/odrive-utilities
