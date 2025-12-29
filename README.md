# odrive Linux Installation Script

Automated installer for [odrive sync agent](https://docs.odrive.com/docs/odrive-sync-agent) on Linux with KDE desktop integration.

## Features

- **Automatic Installation**: Downloads and installs odrive sync agent binaries
- **KDE Integration**: Creates file associations and context menu for Dolphin
- **Idempotent**: Can be run multiple times safely without duplicating work
- **KDE Plasma 5 & 6 Compatible**: Automatically detects and creates appropriate service menus

## Quick Start

```bash
./install-odrive-linux.sh
```

**Options:**
- `./install-odrive-linux.sh` - Normal installation (skip existing files)
- `./install-odrive-linux.sh --check` - Verify installation status without making changes
- `./install-odrive-linux.sh --repair` - Fix missing or broken components
- `./install-odrive-linux.sh --force` - Force complete reinstall (overwrite all files)
- `./install-odrive-linux.sh --help` - Show help message

**The script is idempotent:** You can run it multiple times safely. It will:
- Skip components that are already correctly installed
- Report what's installed vs what's missing (with `--check`)
- Fix only broken/missing components (with `--repair`)
- Overwrite everything only when requested (with `--force`)

**Requirements:**
- Linux system with KDE desktop environment
- `curl` installed
- `python` or `python3` installed
- `odrive-logo.png` file (256×256 square icon) in the same directory as the script

## What the Script Does

1. **Downloads odrive sync agent** (64-bit) to `~/.odrive-agent/bin/`
2. **Creates mount directory** at `~/odrive-agent-mount/`
3. **Installs MIME type icons** to `~/.local/share/icons/hicolor/256x256/mimetypes/`
4. **Creates file associations** for `.cloud` and `.cloudf` files:
   - Double-click on cloud files automatically syncs them
   - Files are associated with odrive in system file manager
5. **Installs MIME type definitions**:
   - Registers `.cloud` and `.cloudf` file extensions with the system
   - Enables proper file recognition and icon display
6. **Adds KDE context menu** in Dolphin:
   - Right-click on `.cloud` and `.cloudf` files shows sync options:
     - "odrive sync" - Sync single file/folder
     - "odrive sync all (recursive)" - Recursively sync entire folder contents
     - "odrive unsync" - Convert back to placeholder
   - Right-click on any folder shows "odrive unsync" option
   - Compatible with both KDE Plasma 5 and 6
7. **Sets up systemd user service** (optional):
   - Enables automatic startup at boot
   - Provides crash recovery and restart functionality

## Setup and Authentication

### 1. Create odrive Account
Create an account at [odrive.com](https://odrive.com) if you don't have one.

### 2. Generate Authentication Key
1. Navigate to your [odrive Auth Codes page](https://www.odrive.com/account/authcodes)
2. Click **"Create Auth Key"**
3. Copy the generated authentication key

### 3. Authenticate the Agent
```bash
python ~/.odrive-agent/bin/odrive.py authenticate [your-auth-key]
```

### 4. Mount Your Cloud Storage

**Mount entire odrive root:**
```bash
python ~/.odrive-agent/bin/odrive.py mount ~/odrive-agent-mount /
```

**Mount specific cloud storage:**
```bash
# Mount Google Drive Documents folder
python ~/.odrive-agent/bin/odrive.py mount ~/Documents "/Google Drive/Documents"

# Mount Dropbox folder
python ~/.odrive-agent/bin/odrive.py mount ~/Dropbox "/Dropbox"
```

**Important Notes:**
- Do not mount root (`/`) to an existing local folder containing data
- Use separate, empty directories for mounting
- Once mounted, `.cloud` and `.cloudf` files represent your cloud content

## Working with Cloud Files

After mounting, you'll see your cloud services as placeholder files:
- **`.cloudf` files**: Folders (not yet synced)
- **`.cloud` files**: Individual files (not yet synced)

### Discover Available Cloud Services
```bash
# Check what cloud services are available
python ~/.odrive-agent/bin/odrive.py syncstate ~/odrive-agent-mount
```

### Sync Cloud Folders and Files

**Sync a cloud folder:**
```bash
# Sync your Google Drive (expands .cloudf to folder)
python ~/.odrive-agent/bin/odrive.py sync ~/odrive-agent-mount/"GDrive Personale.cloudf"

# Sync Dropbox
python ~/.odrive-agent/bin/odrive.py sync ~/odrive-agent-mount/"Dropbox.cloudf"

# Sync OneDrive
python ~/.odrive-agent/bin/odrive.py sync ~/odrive-agent-mount/"OneDrive.cloudf"
```

**Sync individual files:**
```bash
# Download a specific document
python ~/.odrive-agent/bin/odrive.py sync ~/odrive-agent-mount/"MyDocument.pdf.cloud"

# Sync a Google Docs file
python ~/.odrive-agent/bin/odrive.py sync ~/odrive-agent-mount/"My Presentation.gslidesx.cloud"
```

**Sync everything in a folder:**
```bash
# First, sync the folder to see its contents
python ~/.odrive-agent/bin/odrive.py sync ~/odrive-agent-mount/"GDrive Personale.cloudf"

# Then check what's inside
python ~/.odrive-agent/bin/odrive.py syncstate ~/odrive-agent-mount/"GDrive Personale"

# Sync a specific subfolder
python ~/.odrive-agent/bin/odrive.py sync ~/odrive-agent-mount/"GDrive Personale"/"Documents.cloudf"
```

### Bulk Sync Operations

**Sync all cloud files in current folder:**
```bash
# Navigate to your mount point
cd ~/odrive-agent-mount/"GDrive Personale"

# Sync all .cloud files (downloads all files)
find . -name "*.cloud" -exec python ~/.odrive-agent/bin/odrive.py sync "{}" \;

# Sync all .cloudf folders (expands all folders)  
find . -name "*.cloudf" -exec python ~/.odrive-agent/bin/odrive.py sync "{}" \;
```

### Check Sync Status
```bash
# Check overall odrive status
python ~/.odrive-agent/bin/odrive.py status

# Check sync state of a specific folder
python ~/.odrive-agent/bin/odrive.py syncstate ~/odrive-agent-mount/"GDrive Personale"

# Monitor sync progress
python ~/.odrive-agent/bin/odrive.py syncstate ~/odrive-agent-mount --recursive
```

### Selective Sync Examples

**Sync only documents:**
```bash
cd ~/odrive-agent-mount/"GDrive Personale"
find . -name "*.pdf.cloud" -exec python ~/.odrive-agent/bin/odrive.py sync "{}" \;
find . -name "*.gdocx.cloud" -exec python ~/.odrive-agent/bin/odrive.py sync "{}" \;
find . -name "*.gslidesx.cloud" -exec python ~/.odrive-agent/bin/odrive.py sync "{}" \;
```

**Sync a project folder:**
```bash
# Expand the coding projects folder
python ~/.odrive-agent/bin/odrive.py sync ~/odrive-agent-mount/"GDrive Personale"/"Git.cloudf"

# Then sync all repositories inside
cd ~/odrive-agent-mount/"GDrive Personale"/"Git"
find . -name "*.cloudf" -exec python ~/.odrive-agent/bin/odrive.py sync "{}" \;
```

## Systemd Service Management

If you enabled the systemd service during installation:

```bash
# Check service status
systemctl --user status odrive.service

# Start/stop service manually
systemctl --user start odrive.service
systemctl --user stop odrive.service

# View service logs
journalctl --user -u odrive.service

# Disable autostart
systemctl --user disable odrive.service
```

## File Structure Created

```
~/.odrive-agent/bin/                         # odrive binaries
~/odrive-agent-mount/                        # mount point for cloud files
~/.local/share/applications/                 # .desktop files for file associations
~/.local/share/mime/packages/                # MIME type definitions
~/.local/share/icons/hicolor/256x256/mimetypes/  # MIME type icons
~/.config/systemd/user/odrive.service        # systemd user service
~/.local/share/kio/servicemenus/             # KDE6 service menu
~/.local/share/kservices5/ServiceMenus/      # KDE5 service menu (if detected)
```

## MIME Type and Icon Configuration

The installer sets up MIME type associations so that `.cloud` and `.cloudf` files display with the odrive icon and open with the correct application when double-clicked.

### How MIME Types Work

The system uses three components for proper file recognition:

1. **MIME type definitions** (`~/.local/share/mime/packages/odrive-mimetypes.xml`)
2. **Icon theme integration** (`~/.local/share/icons/hicolor/256x256/mimetypes/`)
3. **Desktop file associations** (`~/.local/share/applications/odrive-*.desktop`)

### Icon Installation Details

Icons are installed in the freedesktop.org standard location:

```
~/.local/share/icons/hicolor/256x256/mimetypes/
├── application-odrive-file.png      # Icon for .cloud files
├── application-odrive-folder.png    # Icon for .cloudf files
└── odrive.png                        # Generic odrive icon
```

The installer uses `odrive-logo.png` (256×256) for MIME type icons because:
- It's square, which is required for proper icon theme integration
- 256×256 is a standard size for modern desktop environments
- The icon name follows the pattern `application-<mime-subtype>.png`

### MIME Type Definitions

The `odrive-mimetypes.xml` file defines two MIME types:

```xml
<mime-type type="application/odrive-file">
  <comment>odrive cloud file</comment>
  <icon name="odrive"/>
  <glob pattern="*.cloud" weight="100"/>
</mime-type>
<mime-type type="application/odrive-folder">
  <comment>odrive cloud folder</comment>
  <icon name="odrive"/>
  <glob pattern="*.cloudf" weight="100"/>
</mime-type>
```

The `weight="100"` attribute gives glob pattern matching higher priority over content-based detection.

### Desktop File Icon References

Desktop files use theme-based icon names instead of absolute paths:

```ini
[Desktop Entry]
Icon=application-odrive-file      # Not /path/to/icon.png
MimeType=application/odrive-file;
```

This allows the system to:
- Automatically find icons in the theme directories
- Support different icon themes
- Provide fallback icons if needed

### Known Limitation: Empty .cloudf Files

`.cloudf` placeholder files are often 0 bytes in size. This causes GIO (used by KDE Dolphin) to detect them as `application/x-zerosize` instead of `application/odrive-folder`, because content-based MIME detection takes precedence over extension-based detection for empty files.

**Impact**: Minimal - the files still work correctly:
- ✅ Double-clicking opens them with the correct application
- ✅ System-level MIME type association (`xdg-mime`) is correct
- ✅ Desktop file associations work properly
- ⚠️ Icon may not display in Dolphin for empty `.cloudf` files
- ✅ Non-empty `.cloud` files display icons correctly

### Manual MIME Type Configuration

If you need to manually update MIME types and icons:

```bash
# 1. Update MIME database
update-mime-database ~/.local/share/mime

# 2. Update desktop database
update-desktop-database ~/.local/share/applications/

# 3. Rebuild KDE cache
kbuildsycoca6 --noincremental  # KDE Plasma 6
# or
kbuildsycoca5 --noincremental  # KDE Plasma 5

# 4. Verify MIME type detection
xdg-mime query filetype ~/odrive-agent-mount/file.cloud
xdg-mime query filetype ~/odrive-agent-mount/folder.cloudf

# 5. Check desktop file associations
gio mime application/odrive-file
gio mime application/odrive-folder
```

### Testing Icon Display

To verify icons are correctly configured:

```bash
# Check installed icons
ls -lh ~/.local/share/icons/hicolor/256x256/mimetypes/ | grep odrive

# Test .cloud file detection
gio info ~/odrive-agent-mount/some-file.cloud | grep -E "(content-type|icon)"

# Test .cloudf file detection
gio info ~/odrive-agent-mount/some-folder.cloudf | grep -E "(content-type|icon)"

# Verify MIME type registration
xdg-mime query filetype ~/odrive-agent-mount/test.cloud
# Should output: application/odrive-file

xdg-mime query filetype ~/odrive-agent-mount/test.cloudf
# Should output: application/odrive-folder
```

## Logs and Troubleshooting

### Context Menu Issues
If the right-click context menus don't appear:

1. **Check if service menu files are executable**:
   ```bash
   ls -la ~/.local/share/kio/servicemenus/
   chmod +x ~/.local/share/kio/servicemenus/*.desktop
   ```

2. **Rebuild KDE cache and restart Dolphin**:
   ```bash
   kbuildsycoca6
   update-desktop-database ~/.local/share/applications/
   killall dolphin
   ```
   
   For KDE Plasma 5, use `kbuildsycoca5` instead of `kbuildsycoca6`.

4. **Check recursive sync debug logs**:
   ```bash
   tail -f ~/.odrive-agent/log/recursive-sync-debug.log
   ```

### MIME Type and Icon Issues

If `.cloud` and `.cloudf` files don't show the correct icon:

1. **Verify icons are installed**:
   ```bash
   ls -lh ~/.local/share/icons/hicolor/256x256/mimetypes/ | grep odrive
   ```
   Should show: `application-odrive-file.png`, `application-odrive-folder.png`, `odrive.png`

2. **Check MIME type detection**:
   ```bash
   xdg-mime query filetype ~/odrive-agent-mount/test.cloud
   # Should output: application/odrive-file

   xdg-mime query filetype ~/odrive-agent-mount/test.cloudf
   # Should output: application/odrive-folder
   ```

3. **Rebuild databases**:
   ```bash
   update-mime-database ~/.local/share/mime
   update-desktop-database ~/.local/share/applications/
   kbuildsycoca6 --noincremental
   ```

4. **Verify desktop file icons**:
   ```bash
   grep "^Icon=" ~/.local/share/applications/odrive-*.desktop
   ```
   Should show theme-based names (e.g., `Icon=application-odrive-file`), not absolute paths

5. **Restart file manager**:
   ```bash
   killall dolphin
   dolphin &
   ```

**Note**: Empty `.cloudf` files (0 bytes) may not display icons correctly in Dolphin due to GIO's content-based MIME detection. This is a known limitation and doesn't affect functionality.

### General Troubleshooting
- **odrive agent logs**: `~/.odrive-agent/log/main.log`
- **systemd service logs**: `journalctl --user -u odrive.service`
- **Advanced configuration**: `~/.odrive-agent/odrive_user_general_conf.txt`

## Manual Sync Scripts

For automated syncing, see the forum discussions:
- [odrive sync agent CLI interface](https://forum.odrive.com/t/odrive-sync-agent-a-cli-scriptable-interface-for-odrives-progressive-sync-engine-for-linux-os-x-and-windows/499/13)
- [Linux CLI sync guide](https://forum.odrive.com/t/linux-using-cli-how-to-sync-and-keep-it-synced-a-selected-folder-and-all-its-content/2615/3)

For more advanced Python utilities: [odrive-utilities](https://github.com/amagliul/odrive-utilities)

## Official Documentation

- [odrive sync agent docs](https://docs.odrive.com/docs/odrive-sync-agent)
- [CLI usage guide](https://docs.odrive.com/docs/odrive-sync-agent#using-the-cliagent-all-platforms)
