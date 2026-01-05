#!/bin/bash
# Setup script to move RustDesk config and logs to fast drive
# This script requires sudo privileges

set -e

echo "=== RustDesk Performance Optimization Setup ==="
echo ""

# Step 1: Create directories on fast drive
echo "Creating directories on fast drive..."
sudo mkdir -p /opt/rustdesk/config
sudo mkdir -p /var/log/rustdesk
sudo chown -R $USER:$USER /opt/rustdesk
sudo chown -R $USER:$USER /var/log/rustdesk

# Step 2: Copy config files to fast drive
echo "Copying configuration files to fast drive..."
if [ -d "$HOME/.config/rustdesk.old" ]; then
    cp -r "$HOME/.config/rustdesk.old"/* /opt/rustdesk/config/
    echo "Config files copied from backup"
elif [ -d "$HOME/.config/rustdesk" ]; then
    cp -r "$HOME/.config/rustdesk"/* /opt/rustdesk/config/
    echo "Config files copied from current location"
else
    echo "Warning: No RustDesk config found to copy"
fi

# Step 3: Create symlink
echo "Creating symlink..."
if [ -L "$HOME/.config/rustdesk" ]; then
    rm "$HOME/.config/rustdesk"
fi
if [ -d "$HOME/.config/rustdesk" ]; then
    mv "$HOME/.config/rustdesk" "$HOME/.config/rustdesk.old"
fi
ln -s /opt/rustdesk/config "$HOME/.config/rustdesk"
echo "Symlink created: $HOME/.config/rustdesk -> /opt/rustdesk/config"

# Step 4: Create tmpfs mount for logs (optional, but fastest)
echo ""
echo "Setting up tmpfs for logs..."
sudo mkdir -p /tmp/rustdesk-logs
# Note: tmpfs is already mounted at /tmp, so logs will be in RAM

# Step 5: Verify
echo ""
echo "=== Verification ==="
echo "Config location:"
ls -lah "$HOME/.config/rustdesk"
echo ""
echo "Fast drive locations:"
ls -lah /opt/rustdesk/config/
echo ""
df -h /opt /var/log | grep -E "(Filesystem|/opt|/var/log)"

echo ""
echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Update systemd service to use new log location (if needed)"
echo "2. Clean up broken FUSE mounts"
echo "3. Restart RustDesk service"

