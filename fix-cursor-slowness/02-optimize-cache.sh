#!/bin/bash
# Optimize Cursor IDE cache by moving cache directories to tmpfs (RAM)
# This script requires sudo privileges

set -e

echo "=== Cursor IDE Cache Optimization ==="
echo ""
echo "This script will move cache directories to tmpfs (RAM) for maximum performance."
echo "Note: Cache data will be cleared on reboot (this is normal and acceptable)."
echo ""

read -p "Continue with cache optimization? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Check if Cursor is running
if pgrep -x "cursor" > /dev/null; then
    echo "WARNING: Cursor IDE appears to be running!"
    echo "Please close Cursor IDE before running this script."
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Please close Cursor IDE and try again."
        exit 1
    fi
fi

CURSOR_CONFIG="/opt/cursor/config"
if [ ! -d "$CURSOR_CONFIG" ]; then
    echo "Error: Cursor config not found at $CURSOR_CONFIG"
    echo "Please run 01-setup-fast.sh first to move config to fast drive."
    exit 1
fi

# Create tmpfs cache directory
CACHE_DIR="/tmp/cursor-cache"
echo "Creating tmpfs cache directory at $CACHE_DIR..."
sudo mkdir -p "$CACHE_DIR"
sudo chown -R $USER:$USER "$CACHE_DIR"
sudo chmod 755 "$CACHE_DIR"

# Cache directories to move to tmpfs
CACHE_DIRS=(
    "Cache"
    "CachedData"
    "WebStorage"
    "Code Cache"
)

# Backup original cache locations
BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/backup/cursor"
mkdir -p "$BACKUP_DIR/cache-backup"

echo ""
echo "Moving cache directories to tmpfs..."

for CACHE_NAME in "${CACHE_DIRS[@]}"; do
    CACHE_PATH="$CURSOR_CONFIG/$CACHE_NAME"
    TMPFS_CACHE="$CACHE_DIR/$CACHE_NAME"
    
    if [ -d "$CACHE_PATH" ] || [ -L "$CACHE_PATH" ]; then
        echo ""
        echo "Processing: $CACHE_NAME"
        
        # If it's already a symlink to tmpfs, skip
        if [ -L "$CACHE_PATH" ]; then
            LINK_TARGET=$(readlink "$CACHE_PATH")
            if [[ "$LINK_TARGET" == "$TMPFS_CACHE" ]] || [[ "$LINK_TARGET" == "$CACHE_DIR"* ]]; then
                echo "  Already symlinked to tmpfs, skipping"
                continue
            fi
        fi
        
        # Backup if it exists and is not empty
        if [ -d "$CACHE_PATH" ] && [ "$(ls -A "$CACHE_PATH" 2>/dev/null)" ]; then
            echo "  Backing up existing cache..."
            cp -r "$CACHE_PATH" "$BACKUP_DIR/cache-backup/" 2>/dev/null || true
        fi
        
        # Create directory in tmpfs
        mkdir -p "$TMPFS_CACHE"
        
        # Copy existing cache to tmpfs if it exists
        if [ -d "$CACHE_PATH" ] && [ "$(ls -A "$CACHE_PATH" 2>/dev/null)" ]; then
            echo "  Copying cache data to tmpfs..."
            cp -r "$CACHE_PATH"/* "$TMPFS_CACHE/" 2>/dev/null || true
        fi
        
        # Remove original and create symlink
        if [ -d "$CACHE_PATH" ] || [ -L "$CACHE_PATH" ]; then
            rm -rf "$CACHE_PATH"
        fi
        ln -s "$TMPFS_CACHE" "$CACHE_PATH"
        echo "  Symlink created: $CACHE_PATH -> $TMPFS_CACHE"
    else
        echo ""
        echo "Processing: $CACHE_NAME (not found, creating new)"
        mkdir -p "$TMPFS_CACHE"
        ln -s "$TMPFS_CACHE" "$CACHE_PATH"
        echo "  Symlink created: $CACHE_PATH -> $TMPFS_CACHE"
    fi
done

# Handle Partitions directory (contains browser partitions with cache)
PARTITIONS_DIR="$CURSOR_CONFIG/Partitions"
if [ -d "$PARTITIONS_DIR" ]; then
    echo ""
    echo "Processing: Partitions (browser partitions)"
    
    # Find all partition directories
    for PARTITION in "$PARTITIONS_DIR"/*; do
        if [ -d "$PARTITION" ]; then
            PARTITION_NAME=$(basename "$PARTITION")
            PARTITION_CACHE="$PARTITION/Cache"
            PARTITION_WEBSTORAGE="$PARTITION/Shared Dictionary/cache"
            
            if [ -d "$PARTITION_CACHE" ] || [ -d "$PARTITION_WEBSTORAGE" ]; then
                echo "  Processing partition: $PARTITION_NAME"
                
                # Handle Cache in partition
                if [ -d "$PARTITION_CACHE" ]; then
                    TMPFS_PARTITION_CACHE="$CACHE_DIR/Partitions/$PARTITION_NAME/Cache"
                    mkdir -p "$TMPFS_PARTITION_CACHE"
                    cp -r "$PARTITION_CACHE"/* "$TMPFS_PARTITION_CACHE/" 2>/dev/null || true
                    rm -rf "$PARTITION_CACHE"
                    ln -s "$TMPFS_PARTITION_CACHE" "$PARTITION_CACHE"
                    echo "    Cache symlinked to tmpfs"
                fi
                
                # Handle Shared Dictionary cache in partition
                if [ -d "$PARTITION_WEBSTORAGE" ]; then
                    TMPFS_PARTITION_WEBSTORAGE="$CACHE_DIR/Partitions/$PARTITION_NAME/Shared Dictionary/cache"
                    mkdir -p "$TMPFS_PARTITION_WEBSTORAGE"
                    cp -r "$PARTITION_WEBSTORAGE"/* "$TMPFS_PARTITION_WEBSTORAGE/" 2>/dev/null || true
                    rm -rf "$PARTITION_WEBSTORAGE"
                    mkdir -p "$(dirname "$PARTITION_WEBSTORAGE")"
                    ln -s "$TMPFS_PARTITION_WEBSTORAGE" "$PARTITION_WEBSTORAGE"
                    echo "    WebStorage cache symlinked to tmpfs"
                fi
            fi
        fi
    done
fi

echo ""
echo "=== Verification ==="
echo "Cache directories on tmpfs:"
ls -lah "$CACHE_DIR" 2>/dev/null | head -10
echo ""
echo "Cache symlinks:"
for CACHE_NAME in "${CACHE_DIRS[@]}"; do
    CACHE_PATH="$CURSOR_CONFIG/$CACHE_NAME"
    if [ -L "$CACHE_PATH" ]; then
        echo "  $CACHE_NAME -> $(readlink "$CACHE_PATH")"
    fi
done

echo ""
echo "tmpfs usage:"
df -h /tmp | grep -E "(Filesystem|/tmp)"

echo ""
echo "=== Cache Optimization Complete ==="
echo "Cache directories are now on tmpfs (RAM) for maximum performance."
echo "Note: Cache will be cleared on reboot (this is normal)."
echo ""
echo "Next steps:"
echo "1. Restart Cursor IDE to apply changes"
echo "2. Run 03-verify.sh to verify the optimization"
