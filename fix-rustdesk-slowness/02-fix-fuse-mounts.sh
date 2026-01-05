#!/bin/bash
# Script to clean up broken FUSE mounts for RustDesk

set -e

echo "=== Cleaning up broken RustDesk FUSE mounts ==="

# Unmount existing mounts (they will be recreated by RustDesk on restart)
echo "Unmounting existing FUSE mounts..."

# Try to unmount cliprdr-client
if mountpoint -q /tmp/RustDesk/cliprdr-client 2>/dev/null; then
    echo "Unmounting /tmp/RustDesk/cliprdr-client..."
    fusermount -u /tmp/RustDesk/cliprdr-client 2>/dev/null || \
    sudo umount -l /tmp/RustDesk/cliprdr-client 2>/dev/null || \
    sudo umount /tmp/RustDesk/cliprdr-client 2>/dev/null || true
fi

# Try to unmount cliprdr-server
if mountpoint -q /tmp/RustDesk/cliprdr-server 2>/dev/null; then
    echo "Unmounting /tmp/RustDesk/cliprdr-server..."
    fusermount -u /tmp/RustDesk/cliprdr-server 2>/dev/null || \
    sudo umount -l /tmp/RustDesk/cliprdr-server 2>/dev/null || \
    sudo umount /tmp/RustDesk/cliprdr-server 2>/dev/null || true
fi

# Wait a moment for unmounts to complete
sleep 1

# Clean up any stale mount points and directories
echo "Cleaning up /tmp/RustDesk directory..."
# Remove broken mount points (may require sudo)
sudo rm -rf /tmp/RustDesk/cliprdr-client /tmp/RustDesk/cliprdr-server 2>/dev/null || true
# Ensure directory exists with proper permissions
sudo mkdir -p /tmp/RustDesk
sudo chmod 1777 /tmp/RustDesk

# Check for any remaining FUSE mounts
echo ""
echo "Current RustDesk FUSE mounts:"
mount | grep -i rustdesk || echo "No RustDesk FUSE mounts found (will be recreated on service restart)"

echo ""
echo "=== FUSE cleanup complete ==="
echo "Note: FUSE mounts will be automatically recreated when RustDesk service restarts"

