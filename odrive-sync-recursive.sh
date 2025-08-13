#!/bin/bash

# Recursive odrive sync script with debug logging
# Syncs all .cloud and .cloudf files in a directory recursively

# Set up logging
LOG_FILE="$HOME/.odrive-agent/log/recursive-sync-debug.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log with timestamp
log_debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_debug "=== Recursive Sync Script Started ==="
log_debug "Script: $0"
log_debug "Arguments: $@"
log_debug "Number of arguments: $#"
log_debug "Working directory: $(pwd)"
log_debug "USER: $USER"
log_debug "HOME: $HOME"
log_debug "PATH: $PATH"

TARGET_URL="$1"
TARGET_PATH="$1"

log_debug "Target URL received: '$TARGET_URL'"

# Convert URL to local path if needed (desktop environments may pass file:// URLs)
if [[ "$TARGET_URL" == file://* ]]; then
    TARGET_PATH="${TARGET_URL#file://}"
    TARGET_PATH=$(printf '%b' "${TARGET_PATH//%/\\x}")  # URL decode
    log_debug "Converted URL to path: '$TARGET_PATH'"
else
    log_debug "Using direct path: '$TARGET_PATH'"
fi

if [ -z "$TARGET_PATH" ]; then
    log_debug "ERROR: No target path provided"
    echo "Usage: $0 <path>" >> "$LOG_FILE"
    exit 1
fi

log_debug "Checking if target path exists..."
if [ ! -e "$TARGET_PATH" ]; then
    log_debug "ERROR: Target path does not exist: '$TARGET_PATH'"
    exit 1
fi

log_debug "Target path exists and is accessible"

# Check if odrive.py exists
ODRIVE_PY="$HOME/.odrive-agent/bin/odrive.py"
log_debug "Checking odrive.py at: $ODRIVE_PY"

if [ ! -f "$ODRIVE_PY" ]; then
    log_debug "ERROR: odrive.py not found at $ODRIVE_PY"
    exit 1
fi

log_debug "odrive.py found successfully"

# Check Python availability
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    log_debug "Using python3 command"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
    log_debug "Using python command"
else
    log_debug "ERROR: No python command found"
    exit 1
fi

log_debug "Python command: $PYTHON_CMD"

log_debug "Starting recursive odrive sync for: '$TARGET_PATH'"

# If it's a .cloudf file, sync it first to expand the folder
if [[ "$TARGET_PATH" == *.cloudf ]]; then
    log_debug "Target is a .cloudf file, expanding folder first"
    log_debug "Running: $PYTHON_CMD '$ODRIVE_PY' sync '$TARGET_PATH'"
    
    if "$PYTHON_CMD" "$ODRIVE_PY" sync "$TARGET_PATH" >> "$LOG_FILE" 2>&1; then
        log_debug "Successfully expanded .cloudf file"
    else
        log_debug "ERROR: Failed to expand .cloudf file"
        exit 1
    fi
    
    # Remove .cloudf extension to get the actual directory path
    TARGET_PATH="${TARGET_PATH%.cloudf}"
    log_debug "Updated target path after expansion: '$TARGET_PATH'"
fi

# If it's a .cloud file, just sync it
if [[ "$TARGET_PATH" == *.cloud ]]; then
    log_debug "Target is a .cloud file, syncing directly"
    log_debug "Running: $PYTHON_CMD '$ODRIVE_PY' sync '$TARGET_PATH'"
    
    if "$PYTHON_CMD" "$ODRIVE_PY" sync "$TARGET_PATH" >> "$LOG_FILE" 2>&1; then
        log_debug "Successfully synced .cloud file"
    else
        log_debug "ERROR: Failed to sync .cloud file"
        exit 1
    fi
    
    log_debug "=== Recursive Sync Script Completed Successfully ==="
    exit 0
fi

# If it's a directory, sync all cloud files recursively
if [ -d "$TARGET_PATH" ]; then
    log_debug "Target is a directory, performing recursive sync"
    log_debug "Changing to directory: '$TARGET_PATH'"
    
    if cd "$TARGET_PATH"; then
        log_debug "Successfully changed to target directory"
        log_debug "Current working directory: $(pwd)"
    else
        log_debug "ERROR: Failed to change to target directory"
        exit 1
    fi
    
    log_debug "Finding .cloud and .cloudf files..."
    
    # Find and log all cloud files first
    find . -name "*.cloud*" -type f > "$HOME/.odrive-agent/log/found-files.log" 2>&1
    FOUND_COUNT=$(wc -l < "$HOME/.odrive-agent/log/found-files.log" 2>/dev/null || echo "0")
    log_debug "Found $FOUND_COUNT cloud files to sync"
    
    if [ "$FOUND_COUNT" -eq 0 ]; then
        log_debug "No cloud files found in directory"
        log_debug "=== Recursive Sync Script Completed (No Files) ==="
        exit 0
    fi
    
    # Sync each file
    SYNC_COUNT=0
    while read -r file; do
        if [ -n "$file" ]; then
            log_debug "Syncing file: '$file'"
            if "$PYTHON_CMD" "$ODRIVE_PY" sync "$file" >> "$LOG_FILE" 2>&1; then
                log_debug "Successfully synced: '$file'"
                SYNC_COUNT=$((SYNC_COUNT + 1))
            else
                log_debug "ERROR: Failed to sync: '$file'"
            fi
        fi
    done < "$HOME/.odrive-agent/log/found-files.log"
    
    log_debug "Recursive sync completed. Synced $SYNC_COUNT files"
    log_debug "=== Recursive Sync Script Completed Successfully ==="
else
    log_debug "ERROR: '$TARGET_PATH' is not a valid file or directory"
    exit 1
fi