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
- `./install-odrive-linux.sh --force` - Force reinstall (overwrite existing files)
- `./install-odrive-linux.sh --help` - Show help message

**Requirements:**
- Linux system with KDE desktop environment
- `curl` installed
- `python` or `python3` installed
- `odrive-icon.png` file in the same directory as the script

## What the Script Does

1. **Downloads odrive sync agent** (64-bit) to `~/.odrive-agent/bin/`
2. **Creates mount directory** at `~/odrive-agent-mount/`
3. **Installs icon** to `/usr/share/icons/odrive.png`
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
~/.config/systemd/user/odrive.service        # systemd user service
/usr/share/icons/odrive.png                  # odrive icon
~/.local/share/kio/servicemenus/             # KDE6 service menu
~/.local/share/kservices5/ServiceMenus/      # KDE5 service menu (if detected)
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
