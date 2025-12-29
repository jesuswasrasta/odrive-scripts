#!/bin/bash

# Script to install odrive sync agent on Linux
# Based on notes in odrive-su-linux.md

set -e

# Parse command-line arguments
FORCE_OVERWRITE=false
CHECK_ONLY=false
REPAIR_MODE=false

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Install, verify, or repair odrive sync agent on Linux with KDE integration"
    echo ""
    echo "Options:"
    echo "  -c, --check    Check installation status without making changes"
    echo "  -r, --repair   Repair/fix existing installation (reinstall missing/broken components)"
    echo "  -f, --force    Force overwrite ALL files (complete reinstall)"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                # Normal installation (skip existing files)"
    echo "  $0 --check        # Verify installation status"
    echo "  $0 --repair       # Fix missing or broken components"
    echo "  $0 --force        # Complete reinstall (overwrite everything)"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -r|--repair)
            REPAIR_MODE=true
            shift
            ;;
        -f|--force)
            FORCE_OVERWRITE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Mode display
if [ "$CHECK_ONLY" = true ]; then
    echo "=== Checking odrive sync agent installation ==="
elif [ "$FORCE_OVERWRITE" = true ]; then
    echo "=== Installing odrive sync agent for Linux (FORCE MODE) ==="
elif [ "$REPAIR_MODE" = true ]; then
    echo "=== Repairing odrive sync agent installation ==="
else
    echo "=== Installing odrive sync agent for Linux ==="
fi

# Global counters for check mode
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Utility functions for check/repair mode
check_status() {
    local component="$1"
    local status="$2"  # "OK" or "MISSING" or "BROKEN"
    local details="$3"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [ "$status" = "OK" ]; then
        echo "  ✓ $component: OK"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo "  ✗ $component: $status"
        [ -n "$details" ] && echo "    → $details"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

should_install() {
    # Returns 0 (true) if we should proceed with installation
    # Returns 1 (false) if we should skip

    if [ "$CHECK_ONLY" = true ]; then
        return 1  # Never install in check mode
    fi

    if [ "$FORCE_OVERWRITE" = true ]; then
        return 0  # Always install in force mode
    fi

    if [ "$REPAIR_MODE" = true ]; then
        return 0  # Install in repair mode (will be controlled by file existence checks)
    fi

    return 0  # Install in normal mode (will be controlled by file existence checks)
}

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install it before continuing."
    exit 1
fi

# Check if python is installed
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    echo "Error: python is not installed. Please install it before continuing."
    exit 1
fi

echo "1. Checking odrive sync agent..."

# Create directory and download (64-bit by default)
od="$HOME/.odrive-agent/bin"

# Check if binaries exist
if [ -f "$od/odrive.py" ] && [ -f "$od/odrive" ] && [ -f "$od/odriveagent" ]; then
    if [ "$CHECK_ONLY" = true ]; then
        check_status "odrive binaries" "OK" "$od"
    else
        echo "odrive sync agent already installed in $od"
    fi

    # Skip installation if files exist and not forcing
    if [ "$FORCE_OVERWRITE" = false ] && [ "$REPAIR_MODE" = false ]; then
        : # Do nothing
    elif should_install; then
        echo "Reinstalling odrive sync agent in $od..."
        curl -L "https://dl.odrive.com/odrive-py" --create-dirs -o "$od/odrive.py"
        curl -L "https://dl.odrive.com/odriveagent-lnx-64" | tar -xvzf- -C "$od/"
        curl -L "https://dl.odrive.com/odrivecli-lnx-64" | tar -xvzf- -C "$od/"
        echo "odrive sync agent reinstalled successfully"
    fi
else
    # Binaries missing or incomplete
    if [ "$CHECK_ONLY" = true ]; then
        check_status "odrive binaries" "MISSING" "Expected location: $od"
    elif should_install; then
        echo "Installing odrive sync agent in $od..."
        curl -L "https://dl.odrive.com/odrive-py" --create-dirs -o "$od/odrive.py"
        curl -L "https://dl.odrive.com/odriveagent-lnx-64" | tar -xvzf- -C "$od/"
        curl -L "https://dl.odrive.com/odrivecli-lnx-64" | tar -xvzf- -C "$od/"
        echo "odrive sync agent installed successfully"
    fi
fi

echo "2. Checking mount folder..."
if [ -d "$HOME/odrive-agent-mount" ]; then
    if [ "$CHECK_ONLY" = true ]; then
        check_status "mount folder" "OK" "$HOME/odrive-agent-mount"
    else
        echo "Mount folder already exists: $HOME/odrive-agent-mount"
    fi
else
    if [ "$CHECK_ONLY" = true ]; then
        check_status "mount folder" "MISSING" "Expected: $HOME/odrive-agent-mount"
    elif should_install; then
        mkdir -p "$HOME/odrive-agent-mount"
        echo "Mount folder created: $HOME/odrive-agent-mount"
    fi
fi

echo "3. Setting up odrive icons for MIME types..."
# Install icons in hicolor theme directory for proper MIME type integration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SOURCE="$SCRIPT_DIR/odrive-logo.png"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/mimetypes"

if [ ! -f "$ICON_SOURCE" ]; then
    echo "Error: odrive-logo.png not found in script directory"
    echo "Make sure the odrive-logo.png file is present in $SCRIPT_DIR"
    exit 1
fi

mkdir -p "$ICON_DIR"

# Install MIME type icons
for icon_name in "application-odrive-file.png" "application-odrive-folder.png" "odrive.png"; do
    ICON_PATH="$ICON_DIR/$icon_name"

    if [ -f "$ICON_PATH" ] && [ "$FORCE_OVERWRITE" = false ]; then
        echo "Icon $icon_name already exists"
    else
        if [ "$FORCE_OVERWRITE" = true ] && [ -f "$ICON_PATH" ]; then
            echo "Force overwriting $icon_name..."
        else
            echo "Installing $icon_name..."
        fi
        cp "$ICON_SOURCE" "$ICON_PATH"
    fi
done

echo "Icons installed to $ICON_DIR"

echo "4. Creating .desktop files for file associations..."

# Get script directory for source files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Directory for .desktop files
DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"

# Copy desktop files
for desktop_file in "odrive.desktop" "odrive-file.desktop" "odrive-folder.desktop"; do
    if [ -f "$DESKTOP_DIR/$desktop_file" ] && [ "$FORCE_OVERWRITE" = false ]; then
        echo "File $desktop_file already exists"
    elif [ -f "$SCRIPT_DIR/$desktop_file" ]; then
        if [ "$FORCE_OVERWRITE" = true ] && [ -f "$DESKTOP_DIR/$desktop_file" ]; then
            echo "Force overwriting $desktop_file..."
        else
            echo "Copying $desktop_file..."
        fi
        cp "$SCRIPT_DIR/$desktop_file" "$DESKTOP_DIR/"
        chmod +x "$DESKTOP_DIR/$desktop_file"
    else
        echo "Error: $desktop_file not found in $SCRIPT_DIR"
        exit 1
    fi
done

echo "5. Installing recursive sync helper script..."

# Install recursive sync helper script (with debug logging)
LOCAL_BIN_DIR="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN_DIR"

if [ -f "$LOCAL_BIN_DIR/odrive-sync-recursive.sh" ] && [ "$FORCE_OVERWRITE" = false ]; then
    echo "Recursive sync script already exists"
elif [ -f "$SCRIPT_DIR/odrive-sync-recursive.sh" ]; then
    if [ "$FORCE_OVERWRITE" = true ] && [ -f "$LOCAL_BIN_DIR/odrive-sync-recursive.sh" ]; then
        echo "Force overwriting recursive sync script..."
    else
        echo "Installing recursive sync script..."
    fi
    cp "$SCRIPT_DIR/odrive-sync-recursive.sh" "$LOCAL_BIN_DIR/"
    chmod +x "$LOCAL_BIN_DIR/odrive-sync-recursive.sh"
    
    # Make sure ~/.local/bin is in PATH for desktop applications
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo "Note: Make sure ~/.local/bin is in your PATH for context menus to work"
    fi
    echo "Recursive sync script installed"
else
    echo "Warning: odrive-sync-recursive.sh not found, recursive sync will not work"
fi


echo "6. Installing MIME type definitions..."

# Install MIME type definitions for .cloud and .cloudf files
MIME_DIR="$HOME/.local/share/mime/packages"
mkdir -p "$MIME_DIR"

if [ -f "$MIME_DIR/odrive-mimetypes.xml" ] && [ "$FORCE_OVERWRITE" = false ]; then
    echo "MIME type definitions already exist"
elif [ -f "$SCRIPT_DIR/odrive-mimetypes.xml" ]; then
    if [ "$FORCE_OVERWRITE" = true ] && [ -f "$MIME_DIR/odrive-mimetypes.xml" ]; then
        echo "Force overwriting MIME type definitions..."
    else
        echo "Installing MIME type definitions..."
    fi
    cp "$SCRIPT_DIR/odrive-mimetypes.xml" "$MIME_DIR/"
    
    # Update MIME database
    if command -v update-mime-database &> /dev/null; then
        update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
        echo "MIME database updated"
    fi
else
    echo "Warning: odrive-mimetypes.xml not found, MIME types not installed"
fi

echo "7. Setting up KDE/Dolphin context menu..."

# Detect KDE Plasma version
KDE_VERSION=""
CREATED_DIRS=""

if command -v plasmashell &> /dev/null; then
    PLASMA_VERSION=$(plasmashell --version 2>/dev/null | grep -oP 'plasmashell \K[0-9]+' | head -1)
    if [ -n "$PLASMA_VERSION" ]; then
        if [ "$PLASMA_VERSION" -ge 6 ]; then
            KDE_VERSION="6"
        elif [ "$PLASMA_VERSION" -ge 5 ]; then
            KDE_VERSION="5"
        fi
    fi
fi

# If detection fails, check for specific directories
if [ -z "$KDE_VERSION" ]; then
    if [ -d "/usr/share/plasma" ] && [ -d "/usr/share/kf6" ]; then
        KDE_VERSION="6"
    elif [ -d "/usr/share/plasma" ] && [ -d "/usr/share/kf5" ]; then
        KDE_VERSION="5"
    fi
fi

# Create service menu based on detected version
if [ "$KDE_VERSION" = "5" ]; then
    echo "Detected KDE Plasma 5, creating service menu for KDE5..."
    SERVICE_MENU_DIR="$HOME/.local/share/kservices5/ServiceMenus"
    mkdir -p "$SERVICE_MENU_DIR"
    CREATED_DIRS="- Service menu KDE5: $SERVICE_MENU_DIR"
    
    if [ -f "$SERVICE_MENU_DIR/odriveSync.desktop" ] && [ "$FORCE_OVERWRITE" = false ]; then
        echo "KDE5 service menu already exists"
    elif [ -f "$SCRIPT_DIR/odriveSync-kde5.desktop" ]; then
        if [ "$FORCE_OVERWRITE" = true ] && [ -f "$SERVICE_MENU_DIR/odriveSync.desktop" ]; then
            echo "Force overwriting KDE5 service menu..."
        else
            echo "Copying service menu for KDE5..."
        fi
        cp "$SCRIPT_DIR/odriveSync-kde5.desktop" "$SERVICE_MENU_DIR/odriveSync.desktop"
        chmod +x "$SERVICE_MENU_DIR/odriveSync.desktop"
    else
        echo "Error: odriveSync-kde5.desktop not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Install folder service menu for KDE5
    if [ -f "$SERVICE_MENU_DIR/odriveFolders.desktop" ] && [ "$FORCE_OVERWRITE" = false ]; then
        echo "KDE5 folder service menu already exists"
    elif [ -f "$SCRIPT_DIR/odriveFolders-kde5.desktop" ]; then
        if [ "$FORCE_OVERWRITE" = true ] && [ -f "$SERVICE_MENU_DIR/odriveFolders.desktop" ]; then
            echo "Force overwriting KDE5 folder service menu..."
        else
            echo "Copying folder service menu for KDE5..."
        fi
        cp "$SCRIPT_DIR/odriveFolders-kde5.desktop" "$SERVICE_MENU_DIR/odriveFolders.desktop"
        chmod +x "$SERVICE_MENU_DIR/odriveFolders.desktop"
    else
        echo "Warning: odriveFolders-kde5.desktop not found in $SCRIPT_DIR"
    fi

elif [ "$KDE_VERSION" = "6" ]; then
    echo "Detected KDE Plasma 6, creating service menu for KDE6..."
    SERVICE_MENU_DIR="$HOME/.local/share/kio/servicemenus"
    mkdir -p "$SERVICE_MENU_DIR"
    CREATED_DIRS="- Service menu KDE6: $SERVICE_MENU_DIR"
    
    if [ -f "$SERVICE_MENU_DIR/odriveSync.desktop" ] && [ "$FORCE_OVERWRITE" = false ]; then
        echo "KDE6 service menu already exists"
    elif [ -f "$SCRIPT_DIR/odriveSync-kde6.desktop" ]; then
        if [ "$FORCE_OVERWRITE" = true ] && [ -f "$SERVICE_MENU_DIR/odriveSync.desktop" ]; then
            echo "Force overwriting KDE6 service menu..."
        else
            echo "Copying service menu for KDE6..."
        fi
        cp "$SCRIPT_DIR/odriveSync-kde6.desktop" "$SERVICE_MENU_DIR/odriveSync.desktop"
        chmod +x "$SERVICE_MENU_DIR/odriveSync.desktop"
    else
        echo "Error: odriveSync-kde6.desktop not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Install folder service menu for KDE6
    if [ -f "$SERVICE_MENU_DIR/odriveFolders.desktop" ] && [ "$FORCE_OVERWRITE" = false ]; then
        echo "KDE6 folder service menu already exists"
    elif [ -f "$SCRIPT_DIR/odriveFolders-kde6.desktop" ]; then
        if [ "$FORCE_OVERWRITE" = true ] && [ -f "$SERVICE_MENU_DIR/odriveFolders.desktop" ]; then
            echo "Force overwriting KDE6 folder service menu..."
        else
            echo "Copying folder service menu for KDE6..."
        fi
        cp "$SCRIPT_DIR/odriveFolders-kde6.desktop" "$SERVICE_MENU_DIR/odriveFolders.desktop"
        chmod +x "$SERVICE_MENU_DIR/odriveFolders.desktop"
    else
        echo "Warning: odriveFolders-kde6.desktop not found in $SCRIPT_DIR"
    fi

else
    echo "Warning: Unable to detect KDE Plasma version"
    echo "Creating service menu for both versions for compatibility..."
    
    # KDE5
    SERVICE_MENU_DIR_KDE5="$HOME/.local/share/kservices5/ServiceMenus"
    mkdir -p "$SERVICE_MENU_DIR_KDE5"
    
    if [ -f "$SERVICE_MENU_DIR_KDE5/odriveSync.desktop" ] && [ "$FORCE_OVERWRITE" = false ]; then
        echo "KDE5 service menu already exists (fallback)"
    elif [ -f "$SCRIPT_DIR/odriveSync-kde5.desktop" ]; then
        if [ "$FORCE_OVERWRITE" = true ] && [ -f "$SERVICE_MENU_DIR_KDE5/odriveSync.desktop" ]; then
            echo "Force overwriting KDE5 service menu (fallback)..."
        else
            echo "Copying service menu for KDE5 (fallback)..."
        fi
        cp "$SCRIPT_DIR/odriveSync-kde5.desktop" "$SERVICE_MENU_DIR_KDE5/odriveSync.desktop"
        chmod +x "$SERVICE_MENU_DIR_KDE5/odriveSync.desktop"
    else
        echo "Error: odriveSync-kde5.desktop not found"
        exit 1
    fi
    
    # Install folder service menu for KDE5 (fallback)
    if [ -f "$SERVICE_MENU_DIR_KDE5/odriveFolders.desktop" ] && [ "$FORCE_OVERWRITE" = false ]; then
        echo "KDE5 folder service menu already exists (fallback)"
    elif [ -f "$SCRIPT_DIR/odriveFolders-kde5.desktop" ]; then
        if [ "$FORCE_OVERWRITE" = true ] && [ -f "$SERVICE_MENU_DIR_KDE5/odriveFolders.desktop" ]; then
            echo "Force overwriting KDE5 folder service menu (fallback)..."
        else
            echo "Copying folder service menu for KDE5 (fallback)..."
        fi
        cp "$SCRIPT_DIR/odriveFolders-kde5.desktop" "$SERVICE_MENU_DIR_KDE5/odriveFolders.desktop"
        chmod +x "$SERVICE_MENU_DIR_KDE5/odriveFolders.desktop"
    else
        echo "Warning: odriveFolders-kde5.desktop not found"
    fi
    
    # KDE6
    SERVICE_MENU_DIR_KDE6="$HOME/.local/share/kio/servicemenus"
    mkdir -p "$SERVICE_MENU_DIR_KDE6"
    
    if [ -f "$SERVICE_MENU_DIR_KDE6/odriveSync.desktop" ] && [ "$FORCE_OVERWRITE" = false ]; then
        echo "KDE6 service menu already exists (fallback)"
    elif [ -f "$SCRIPT_DIR/odriveSync-kde6.desktop" ]; then
        if [ "$FORCE_OVERWRITE" = true ] && [ -f "$SERVICE_MENU_DIR_KDE6/odriveSync.desktop" ]; then
            echo "Force overwriting KDE6 service menu (fallback)..."
        else
            echo "Copying service menu for KDE6 (fallback)..."
        fi
        cp "$SCRIPT_DIR/odriveSync-kde6.desktop" "$SERVICE_MENU_DIR_KDE6/odriveSync.desktop"
        chmod +x "$SERVICE_MENU_DIR_KDE6/odriveSync.desktop"
    else
        echo "Error: odriveSync-kde6.desktop not found"
        exit 1
    fi
    
    # Install folder service menu for KDE6 (fallback)
    if [ -f "$SERVICE_MENU_DIR_KDE6/odriveFolders.desktop" ] && [ "$FORCE_OVERWRITE" = false ]; then
        echo "KDE6 folder service menu already exists (fallback)"
    elif [ -f "$SCRIPT_DIR/odriveFolders-kde6.desktop" ]; then
        if [ "$FORCE_OVERWRITE" = true ] && [ -f "$SERVICE_MENU_DIR_KDE6/odriveFolders.desktop" ]; then
            echo "Force overwriting KDE6 folder service menu (fallback)..."
        else
            echo "Copying folder service menu for KDE6 (fallback)..."
        fi
        cp "$SCRIPT_DIR/odriveFolders-kde6.desktop" "$SERVICE_MENU_DIR_KDE6/odriveFolders.desktop"
        chmod +x "$SERVICE_MENU_DIR_KDE6/odriveFolders.desktop"
    else
        echo "Warning: odriveFolders-kde6.desktop not found"
    fi

    CREATED_DIRS="- Service menu KDE5: $SERVICE_MENU_DIR_KDE5
- Service menu KDE6: $SERVICE_MENU_DIR_KDE6"
fi

echo "8. Updating desktop database and KDE cache..."

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    echo "Desktop database updated"
fi

# Rebuild KDE system configuration cache
if [ "$KDE_VERSION" = "6" ]; then
    if command -v kbuildsycoca6 &> /dev/null; then
        kbuildsycoca6 --noincremental 2>/dev/null || true
        echo "KDE6 cache rebuilt"
    fi
elif [ "$KDE_VERSION" = "5" ]; then
    if command -v kbuildsycoca5 &> /dev/null; then
        kbuildsycoca5 --noincremental 2>/dev/null || true
        echo "KDE5 cache rebuilt"
    fi
else
    # Try both if version is unknown
    if command -v kbuildsycoca6 &> /dev/null; then
        kbuildsycoca6 --noincremental 2>/dev/null || true
        echo "KDE6 cache rebuilt"
    fi
    if command -v kbuildsycoca5 &> /dev/null; then
        kbuildsycoca5 --noincremental 2>/dev/null || true
        echo "KDE5 cache rebuilt"
    fi
fi

echo "9. Setting up systemd user service..."

# Create systemd user service directory
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

# Install systemd service file
if [ -f "$SYSTEMD_USER_DIR/odrive.service" ] && [ "$FORCE_OVERWRITE" = false ]; then
    echo "Systemd service already exists"
elif [ -f "$SCRIPT_DIR/odrive.service" ]; then
    if [ "$FORCE_OVERWRITE" = true ] && [ -f "$SYSTEMD_USER_DIR/odrive.service" ]; then
        echo "Force overwriting systemd service..."
    else
        echo "Copying systemd service..."
    fi
    cp "$SCRIPT_DIR/odrive.service" "$SYSTEMD_USER_DIR/"
    echo "Systemd service installed"
else
    echo "Warning: odrive.service not found, systemd service not installed"
fi

# Ask user if they want to enable the service (skip in check mode)
if [ "$CHECK_ONLY" = false ]; then
    echo ""
    echo "Do you want to enable automatic odrive startup? (y/N)"
    read -r enable_service
else
    enable_service="n"
fi

if [[ "$enable_service" =~ ^[Yy]$ ]]; then
    echo "Enabling systemd service..."
    
    # Enable lingering to allow user services to start at boot
    if ! loginctl show-user "$USER" --property=Linger | grep -q "Linger=yes"; then
        echo "Enabling lingering for user..."
        loginctl enable-linger "$USER"
    fi
    
    # Reload systemd user daemon
    systemctl --user daemon-reload
    
    # Enable and start the service
    if systemctl --user enable odrive.service 2>/dev/null; then
        echo "Service enabled for automatic startup"
        
        if systemctl --user start odrive.service 2>/dev/null; then
            echo "Service started successfully"
            echo "Check status with: systemctl --user status odrive.service"
        else
            echo "Warning: Unable to start service now (probably odrive is not yet authenticated)"
            echo "The service will start automatically after authentication"
        fi
    else
        echo "Error enabling systemd service"
    fi
else
    echo "Systemd service not enabled. You can do it manually later with:"
    echo "  systemctl --user enable odrive.service"
    echo "  systemctl --user start odrive.service"
fi

echo ""

# Display summary based on mode
if [ "$CHECK_ONLY" = true ]; then
    echo "=== Installation Check Complete ==="
    echo ""
    echo "Status Summary:"
    echo "  Total components checked: $TOTAL_CHECKS"
    echo "  ✓ Working correctly: $PASSED_CHECKS"
    echo "  ✗ Issues found: $FAILED_CHECKS"
    echo ""

    if [ $FAILED_CHECKS -gt 0 ]; then
        echo "To fix issues, run:"
        echo "  $0 --repair    # Fix missing/broken components"
        echo "  $0 --force     # Complete reinstall"
        exit 1
    else
        echo "✓ All components are correctly installed!"
        exit 0
    fi
elif [ "$REPAIR_MODE" = true ]; then
    echo "=== Repair completed! ==="
    echo ""
    if [ $FAILED_CHECKS -gt 0 ]; then
        echo "⚠ Some issues may remain. Run with --check to verify:"
        echo "  $0 --check"
    else
        echo "✓ Installation repaired successfully!"
    fi
else
    echo "=== Installation completed! ==="
fi

echo ""
echo "Next manual steps:"
echo "1. Create an account on odrive.com if you don't have one"
echo "2. Generate an authentication key from your odrive account"
echo "3. Authenticate the agent with: python \"$HOME/.odrive-agent/bin/odrive.py\" authenticate [your-auth-key]"
echo "4. Mount odrive with: python \"$HOME/.odrive-agent/bin/odrive.py\" mount \"$HOME/odrive-agent-mount\" /"
echo ""
echo "Configuration files location:"
echo "- odrive binaries: $HOME/.odrive-agent/bin/"
echo "- Mount folder: $HOME/odrive-agent-mount/"
echo "- .desktop files: $HOME/.local/share/applications/"
echo "- MIME type icons: $HOME/.local/share/icons/hicolor/256x256/mimetypes/"
echo "- MIME type definitions: $HOME/.local/share/mime/packages/"
echo "- Systemd service: $HOME/.config/systemd/user/"
echo "$CREATED_DIRS"
echo ""
echo "Useful commands:"
echo "- Check installation: $0 --check"
echo "- Repair installation: $0 --repair"
echo "- Service status: systemctl --user status odrive.service"
echo "- Start service: systemctl --user start odrive.service"
echo "- Stop service: systemctl --user stop odrive.service"
echo "- Service logs: journalctl --user -u odrive.service"
echo "- odrive logs: $HOME/.odrive-agent/log/main.log"