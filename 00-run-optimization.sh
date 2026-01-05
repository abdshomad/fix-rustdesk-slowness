#!/bin/bash
# Master script to run all RustDesk optimization steps
# This script requires sudo privileges

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "RustDesk Performance Optimization"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Move configuration to fast drive"
echo "2. Fix broken FUSE mounts"
echo "3. Configure logs to use tmpfs"
echo "4. Restart RustDesk service"
echo "5. Verify the changes"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Step 1: Setup fast drive
echo ""
echo "=== Step 1: Setting up fast drive storage ==="
./01-setup-rustdesk-fast.sh

# Step 2: Fix FUSE mounts
echo ""
echo "=== Step 2: Fixing FUSE mounts ==="
./02-fix-fuse-mounts.sh

# Step 3: Create systemd override
echo ""
echo "=== Step 3: Configuring log location ==="
./03-create-systemd-override.sh

# Step 4: Restart service
echo ""
echo "=== Step 4: Restarting RustDesk service ==="
sudo systemctl restart rustdesk
sleep 2
sudo systemctl status rustdesk --no-pager | head -15

# Step 5: Verify
echo ""
echo "=== Step 5: Verifying changes ==="
./04-monitor-performance.sh

echo ""
echo "=========================================="
echo "Optimization Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "- Test RustDesk screen sharing to verify performance improvement"
echo "- Run './04-monitor-performance.sh' anytime to check status"
echo "- Check logs at /tmp/rustdesk-data/logs/RustDesk (tmpfs - fast!)"

