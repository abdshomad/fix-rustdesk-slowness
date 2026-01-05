#!/bin/bash
# Setup script to move Cursor IDE config and agent to fast drive
# This script requires sudo privileges

set -e

echo "=== Cursor IDE Performance Optimization Setup ==="
echo ""

# Check if Cursor is running
if pgrep -x "cursor" > /dev/null; then
    echo "WARNING: Cursor IDE appears to be running!"
    echo "Please close Cursor IDE before running this script."
    echo "Running processes:"
    pgrep -x "cursor" | xargs ps -p
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Please close Cursor IDE and try again."
        exit 1
    fi
fi

# Step 1: Create backup
echo "Creating backup of current Cursor data..."
BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/backup/cursor"
mkdir -p "$BACKUP_DIR"

if [ -d "$HOME/.config/Cursor" ]; then
    echo "Backing up ~/.config/Cursor..."
    if [ -d "$BACKUP_DIR/config" ]; then
        echo "Backup already exists at $BACKUP_DIR/config"
        read -p "Overwrite existing backup? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$BACKUP_DIR/config"
            cp -r "$HOME/.config/Cursor" "$BACKUP_DIR/config"
            echo "Backup updated"
        else
            echo "Using existing backup"
        fi
    else
        cp -r "$HOME/.config/Cursor" "$BACKUP_DIR/config"
        echo "Backup created at $BACKUP_DIR/config"
    fi
fi

if [ -d "$HOME/.local/share/cursor-agent" ]; then
    echo "Backing up ~/.local/share/cursor-agent..."
    if [ -d "$BACKUP_DIR/cursor-agent" ]; then
        echo "Backup already exists at $BACKUP_DIR/cursor-agent"
        read -p "Overwrite existing backup? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$BACKUP_DIR/cursor-agent"
            cp -r "$HOME/.local/share/cursor-agent" "$BACKUP_DIR/cursor-agent"
            echo "Backup updated"
        else
            echo "Using existing backup"
        fi
    else
        cp -r "$HOME/.local/share/cursor-agent" "$BACKUP_DIR/cursor-agent"
        echo "Backup created at $BACKUP_DIR/cursor-agent"
    fi
fi

# Step 2: Create directories on fast drive
echo ""
echo "Creating directories on fast drive..."
sudo mkdir -p /opt/cursor/config
sudo mkdir -p /opt/cursor/cursor-agent
sudo chown -R $USER:$USER /opt/cursor

# Step 3: Copy config files to fast drive
echo ""
echo "Copying configuration files to fast drive..."
if [ -d "$HOME/.config/Cursor" ]; then
    if [ -L "$HOME/.config/Cursor" ]; then
        echo "~/.config/Cursor is already a symlink, skipping copy"
    elif [ -d "/opt/cursor/config" ] && [ "$(ls -A /opt/cursor/config 2>/dev/null)" ]; then
        echo "Fast drive location already contains data"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf /opt/cursor/config/*
            cp -r "$HOME/.config/Cursor"/* /opt/cursor/config/
            echo "Config files copied to fast drive"
        else
            echo "Using existing data on fast drive"
        fi
    else
        cp -r "$HOME/.config/Cursor"/* /opt/cursor/config/
        echo "Config files copied to fast drive"
    fi
else
    echo "Warning: No Cursor config found to copy"
fi

# Step 4: Copy cursor-agent to fast drive
echo ""
echo "Copying cursor-agent to fast drive..."
if [ -d "$HOME/.local/share/cursor-agent" ]; then
    if [ -L "$HOME/.local/share/cursor-agent" ]; then
        echo "~/.local/share/cursor-agent is already a symlink, skipping copy"
    elif [ -d "/opt/cursor/cursor-agent" ] && [ "$(ls -A /opt/cursor/cursor-agent 2>/dev/null)" ]; then
        echo "Fast drive location already contains data"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf /opt/cursor/cursor-agent/*
            cp -r "$HOME/.local/share/cursor-agent"/* /opt/cursor/cursor-agent/
            echo "Cursor-agent files copied to fast drive"
        else
            echo "Using existing data on fast drive"
        fi
    else
        cp -r "$HOME/.local/share/cursor-agent"/* /opt/cursor/cursor-agent/
        echo "Cursor-agent files copied to fast drive"
    fi
else
    echo "Warning: No cursor-agent found to copy"
fi

# Step 5: Create symlinks
echo ""
echo "Creating symlinks..."

# Handle ~/.config/Cursor
if [ -L "$HOME/.config/Cursor" ]; then
    echo "~/.config/Cursor is already a symlink"
    CURRENT_LINK=$(readlink "$HOME/.config/Cursor")
    if [ "$CURRENT_LINK" != "/opt/cursor/config" ]; then
        echo "Current symlink points to: $CURRENT_LINK"
        read -p "Replace with link to /opt/cursor/config? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$HOME/.config/Cursor"
            ln -s /opt/cursor/config "$HOME/.config/Cursor"
            echo "Symlink updated: $HOME/.config/Cursor -> /opt/cursor/config"
        fi
    else
        echo "Symlink already points to correct location"
    fi
elif [ -d "$HOME/.config/Cursor" ]; then
    mv "$HOME/.config/Cursor" "$HOME/.config/Cursor.old"
    ln -s /opt/cursor/config "$HOME/.config/Cursor"
    echo "Symlink created: $HOME/.config/Cursor -> /opt/cursor/config"
    echo "Original directory backed up as ~/.config/Cursor.old"
else
    ln -s /opt/cursor/config "$HOME/.config/Cursor"
    echo "Symlink created: $HOME/.config/Cursor -> /opt/cursor/config"
fi

# Handle ~/.local/share/cursor-agent
if [ -L "$HOME/.local/share/cursor-agent" ]; then
    echo "~/.local/share/cursor-agent is already a symlink"
    CURRENT_LINK=$(readlink "$HOME/.local/share/cursor-agent")
    if [ "$CURRENT_LINK" != "/opt/cursor/cursor-agent" ]; then
        echo "Current symlink points to: $CURRENT_LINK"
        read -p "Replace with link to /opt/cursor/cursor-agent? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$HOME/.local/share/cursor-agent"
            ln -s /opt/cursor/cursor-agent "$HOME/.local/share/cursor-agent"
            echo "Symlink updated: $HOME/.local/share/cursor-agent -> /opt/cursor/cursor-agent"
        fi
    else
        echo "Symlink already points to correct location"
    fi
elif [ -d "$HOME/.local/share/cursor-agent" ]; then
    mv "$HOME/.local/share/cursor-agent" "$HOME/.local/share/cursor-agent.old"
    ln -s /opt/cursor/cursor-agent "$HOME/.local/share/cursor-agent"
    echo "Symlink created: $HOME/.local/share/cursor-agent -> /opt/cursor/cursor-agent"
    echo "Original directory backed up as ~/.local/share/cursor-agent.old"
else
    mkdir -p "$HOME/.local/share"
    ln -s /opt/cursor/cursor-agent "$HOME/.local/share/cursor-agent"
    echo "Symlink created: $HOME/.local/share/cursor-agent -> /opt/cursor/cursor-agent"
fi

# Step 6: Verify
echo ""
echo "=== Verification ==="
echo "Config location:"
ls -lah "$HOME/.config/Cursor" 2>/dev/null || echo "Symlink not found"
echo ""
echo "Cursor-agent location:"
ls -lah "$HOME/.local/share/cursor-agent" 2>/dev/null || echo "Symlink not found"
echo ""
echo "Fast drive locations:"
ls -lah /opt/cursor/config/ 2>/dev/null | head -5
echo ""
ls -lah /opt/cursor/cursor-agent/ 2>/dev/null | head -5
echo ""
df -h /opt | grep -E "(Filesystem|/opt)"

echo ""
echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Optionally run 02-optimize-cache.sh to move cache to tmpfs"
echo "2. Restart Cursor IDE to apply changes"
echo "3. Run 03-verify.sh to verify the optimization"
