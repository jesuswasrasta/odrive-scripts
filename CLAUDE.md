# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides automated installation and desktop integration for odrive sync agent on Linux systems with KDE. The main component is a comprehensive installer script that sets up odrive with file associations, context menus, and systemd service integration.

## Repository Structure

- `install-odrive-linux.sh` - Main installer script for Linux odrive setup with KDE integration
- `README.md` - Comprehensive documentation with setup instructions and usage examples
- Desktop integration files:
  - `odrive.desktop` - Main application launcher
  - `odrive-file.desktop` / `odrive-folder.desktop` - File associations for .cloud/.cloudf files
  - `odriveSync-kde5.desktop` / `odriveSync-kde6.desktop` - KDE Dolphin context menu entries
- Assets:
  - `odrive-icon.png` / `odrive-logo.png` / `odrive-file.png` / `odrive-folder.png` - UI icons
  - `odrive-mimetypes.xml` - MIME type definitions for cloud file extensions
  - `odrive.service` - systemd user service configuration

## Installation Architecture

### install-odrive-linux.sh
The installer performs these operations in sequence:

1. **Downloads odrive binaries** to `~/.odrive-agent/bin/` (64-bit Linux)
2. **Creates mount directory** at `~/odrive-agent-mount/`
3. **Installs system icon** to `/usr/share/icons/odrive.png`
4. **Sets up file associations** by copying .desktop files to `~/.local/share/applications/`
5. **Configures KDE context menus** with version detection (Plasma 5 vs 6)
6. **Updates desktop database** for file associations
7. **Installs systemd user service** with optional auto-enable

### KDE Integration Strategy
- Detects KDE Plasma version (5 vs 6) using `plasmashell --version`
- Falls back to directory-based detection (`/usr/share/kf5` vs `/usr/share/kf6`)
- Creates appropriate service menus in version-specific directories:
  - KDE5: `~/.local/share/kservices5/ServiceMenus/`  
  - KDE6: `~/.local/share/kio/servicemenus/`
- Handles unknown versions by installing both variants

### Idempotent Design
The script can be run multiple times safely by checking for existing files before installation.

## Key Configuration Paths

- odrive binaries: `~/.odrive-agent/bin/`
- Mount point: `~/odrive-agent-mount/`
- Desktop files: `~/.local/share/applications/`
- Systemd service: `~/.config/systemd/user/odrive.service`
- System icon: `/usr/share/icons/odrive.png`

## Testing Commands

```bash
# Test installation script
./install-odrive-linux.sh

# Check systemd service status  
systemctl --user status odrive.service

# Test desktop database update
update-desktop-database ~/.local/share/applications/

# Verify KDE context menu installation
ls ~/.local/share/kio/servicemenus/
ls ~/.local/share/kservices5/ServiceMenus/
```

## Dependencies

Required for installation:
- `curl` - for downloading odrive binaries
- `python` or `python3` - for running odrive CLI
- Linux system with KDE desktop environment
- All asset files (icons, .desktop files) present in script directory

## Related Resources

- odrive sync agent documentation: https://docs.odrive.com/docs/odrive-sync-agent
- odrive forum CLI discussions: https://forum.odrive.com/t/odrive-sync-agent-a-cli-scriptable-interface-for-odrives-progressive-sync-engine-for-linux-os-x-and-windows/499/13
- Advanced Python utilities: https://github.com/amagliul/odrive-utilities