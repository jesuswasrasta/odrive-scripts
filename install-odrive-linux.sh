#!/bin/bash

# Script to install odrive sync agent on Linux
# Based on notes in odrive-su-linux.md

set -e

echo "=== Installing odrive sync agent for Linux ==="

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

echo "1. Downloading and installing odrive sync agent..."

# Create directory and download (64-bit by default)
od="$HOME/.odrive-agent/bin"

if [ -f "$od/odrive.py" ] && [ -f "$od/odrive" ]; then
    echo "odrive sync agent already installed in $od"
else
    echo "Installing odrive sync agent in $od..."
    curl -L "https://dl.odrive.com/odrive-py" --create-dirs -o "$od/odrive.py"
    curl -L "https://dl.odrive.com/odriveagent-lnx-64" | tar -xvzf- -C "$od/"
    curl -L "https://dl.odrive.com/odrivecli-lnx-64" | tar -xvzf- -C "$od/"
    echo "odrive sync agent installed successfully"
fi

echo "2. Creating mount folder..."
if [ ! -d "$HOME/odrive-agent-mount" ]; then
    mkdir -p "$HOME/odrive-agent-mount"
    echo "Mount folder created: $HOME/odrive-agent-mount"
else
    echo "Mount folder already exists: $HOME/odrive-agent-mount"
fi

echo "3. Setting up odrive icon..."
# Copy odrive icon from current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SOURCE="$SCRIPT_DIR/odrive-icon.png"
ICON_PATH="/usr/share/icons/odrive.png"

if [ -f "$ICON_PATH" ]; then
    echo "odrive icon already exists in $ICON_PATH"
elif [ -f "$ICON_SOURCE" ]; then
    echo "Copying odrive icon from $ICON_SOURCE..."
    sudo mkdir -p /usr/share/icons
    sudo cp "$ICON_SOURCE" "$ICON_PATH"
    echo "Icon copied to $ICON_PATH"
else
    echo "Error: odrive-icon.png not found in script directory"
    echo "Make sure the odrive-icon.png file is present in $SCRIPT_DIR"
    exit 1
fi

echo "4. Creating .desktop files for file associations..."

# Get script directory for source files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Directory for .desktop files
DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"

# Copy desktop files
for desktop_file in "odrive.desktop" "odrive-file.desktop" "odrive-folder.desktop"; do
    if [ -f "$DESKTOP_DIR/$desktop_file" ]; then
        echo "File $desktop_file already exists"
    elif [ -f "$SCRIPT_DIR/$desktop_file" ]; then
        echo "Copying $desktop_file..."
        cp "$SCRIPT_DIR/$desktop_file" "$DESKTOP_DIR/"
    else
        echo "Error: $desktop_file not found in $SCRIPT_DIR"
        exit 1
    fi
done

echo "5. Setting up KDE/Dolphin context menu..."

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
    
    if [ -f "$SERVICE_MENU_DIR/odriveSync.desktop" ]; then
        echo "KDE5 service menu already exists"
    elif [ -f "$SCRIPT_DIR/odriveSync-kde5.desktop" ]; then
        echo "Copying service menu for KDE5..."
        cp "$SCRIPT_DIR/odriveSync-kde5.desktop" "$SERVICE_MENU_DIR/odriveSync.desktop"
    else
        echo "Error: odriveSync-kde5.desktop not found in $SCRIPT_DIR"
        exit 1
    fi

elif [ "$KDE_VERSION" = "6" ]; then
    echo "Detected KDE Plasma 6, creating service menu for KDE6..."
    SERVICE_MENU_DIR="$HOME/.local/share/kio/servicemenus"
    mkdir -p "$SERVICE_MENU_DIR"
    CREATED_DIRS="- Service menu KDE6: $SERVICE_MENU_DIR"
    
    if [ -f "$SERVICE_MENU_DIR/odriveSync.desktop" ]; then
        echo "KDE6 service menu already exists"
    elif [ -f "$SCRIPT_DIR/odriveSync-kde6.desktop" ]; then
        echo "Copying service menu for KDE6..."
        cp "$SCRIPT_DIR/odriveSync-kde6.desktop" "$SERVICE_MENU_DIR/odriveSync.desktop"
    else
        echo "Error: odriveSync-kde6.desktop not found in $SCRIPT_DIR"
        exit 1
    fi

else
    echo "Warning: Unable to detect KDE Plasma version"
    echo "Creating service menu for both versions for compatibility..."
    
    # KDE5
    SERVICE_MENU_DIR_KDE5="$HOME/.local/share/kservices5/ServiceMenus"
    mkdir -p "$SERVICE_MENU_DIR_KDE5"
    
    if [ -f "$SERVICE_MENU_DIR_KDE5/odriveSync.desktop" ]; then
        echo "KDE5 service menu already exists (fallback)"
    elif [ -f "$SCRIPT_DIR/odriveSync-kde5.desktop" ]; then
        echo "Copying service menu for KDE5 (fallback)..."
        cp "$SCRIPT_DIR/odriveSync-kde5.desktop" "$SERVICE_MENU_DIR_KDE5/odriveSync.desktop"
    else
        echo "Error: odriveSync-kde5.desktop not found"
        exit 1
    fi
    
    # KDE6
    SERVICE_MENU_DIR_KDE6="$HOME/.local/share/kio/servicemenus"
    mkdir -p "$SERVICE_MENU_DIR_KDE6"
    
    if [ -f "$SERVICE_MENU_DIR_KDE6/odriveSync.desktop" ]; then
        echo "KDE6 service menu already exists (fallback)"
    elif [ -f "$SCRIPT_DIR/odriveSync-kde6.desktop" ]; then
        echo "Copying service menu for KDE6 (fallback)..."
        cp "$SCRIPT_DIR/odriveSync-kde6.desktop" "$SERVICE_MENU_DIR_KDE6/odriveSync.desktop"
    else
        echo "Error: odriveSync-kde6.desktop not found"
        exit 1
    fi

    CREATED_DIRS="- Service menu KDE5: $SERVICE_MENU_DIR_KDE5
- Service menu KDE6: $SERVICE_MENU_DIR_KDE6"
fi

echo "6. Updating desktop database..."
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo "7. Setting up systemd user service..."

# Create systemd user service directory
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

# Install systemd service file
if [ -f "$SYSTEMD_USER_DIR/odrive.service" ]; then
    echo "Systemd service already exists"
elif [ -f "$SCRIPT_DIR/odrive.service" ]; then
    echo "Copying systemd service..."
    cp "$SCRIPT_DIR/odrive.service" "$SYSTEMD_USER_DIR/"
    echo "Systemd service installed"
else
    echo "Warning: odrive.service not found, systemd service not installed"
fi

# Ask user if they want to enable the service
echo ""
echo "Do you want to enable automatic odrive startup? (y/N)"
read -r enable_service

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
echo "=== Installation completed! ==="
echo ""
echo "Next manual steps:"
echo "1. Create an account on odrive.com if you don't have one"
echo "2. Generate an authentication key from your odrive account"
echo "3. Authenticate the agent with: python \"$HOME/.odrive-agent/bin/odrive.py\" authenticate [your-auth-key]"
echo "4. Mount odrive with: python \"$HOME/.odrive-agent/bin/odrive.py\" mount \"$HOME/odrive-agent-mount\" /"
echo ""
echo "Configuration files created:"
echo "- odrive binaries: $HOME/.odrive-agent/bin/"
echo "- Mount folder: $HOME/odrive-agent-mount/"
echo "- .desktop files: $HOME/.local/share/applications/"
echo "- Systemd service: $HOME/.config/systemd/user/"
echo "$CREATED_DIRS"
echo ""
echo "Useful commands:"
echo "- Check service status: systemctl --user status odrive.service"
echo "- Start service: systemctl --user start odrive.service"
echo "- Stop service: systemctl --user stop odrive.service"
echo "- Service logs: journalctl --user -u odrive.service"
echo "- odrive logs: $HOME/.odrive-agent/log/main.log"