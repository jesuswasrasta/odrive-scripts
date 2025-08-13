#!/bin/bash

# Recursive odrive sync script
# Syncs all .cloud and .cloudf files in a directory recursively

TARGET_PATH="$1"

if [ -z "$TARGET_PATH" ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

echo "Starting recursive odrive sync for: $TARGET_PATH"

# If it's a .cloudf file, sync it first to expand the folder
if [[ "$TARGET_PATH" == *.cloudf ]]; then
    echo "Expanding folder: $TARGET_PATH"
    python "$HOME/.odrive-agent/bin/odrive.py" sync "$TARGET_PATH"
    # Remove .cloudf extension to get the actual directory path
    TARGET_PATH="${TARGET_PATH%.cloudf}"
fi

# If it's a .cloud file, just sync it
if [[ "$TARGET_PATH" == *.cloud ]]; then
    echo "Syncing file: $TARGET_PATH"
    python "$HOME/.odrive-agent/bin/odrive.py" sync "$TARGET_PATH"
    exit 0
fi

# If it's a directory, sync all cloud files recursively
if [ -d "$TARGET_PATH" ]; then
    echo "Recursively syncing all cloud files in: $TARGET_PATH"
    cd "$TARGET_PATH" || exit 1
    
    # Find and sync all .cloud and .cloudf files
    find . -name "*.cloud*" -type f | while read -r file; do
        echo "Syncing: $file"
        python "$HOME/.odrive-agent/bin/odrive.py" sync "$file"
    done
    
    echo "Recursive sync completed for: $TARGET_PATH"
else
    echo "Error: $TARGET_PATH is not a valid file or directory"
    exit 1
fi