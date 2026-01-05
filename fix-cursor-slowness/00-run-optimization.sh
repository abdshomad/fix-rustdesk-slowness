#!/bin/bash
# Master script to run all Cursor IDE optimization steps
# This script requires sudo privileges

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Cursor IDE Performance Optimization"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Move configuration and agent to fast drive"
echo "2. Optionally move cache to tmpfs (RAM)"
echo "3. Verify the changes"
echo ""
echo "WARNING: Cursor IDE must be closed before running this script!"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Check if Cursor is running
if pgrep -x "cursor" > /dev/null; then
    echo ""
    echo "ERROR: Cursor IDE is currently running!"
    echo "Please close Cursor IDE completely before running this optimization."
    echo ""
    echo "Running processes:"
    pgrep -x "cursor" | xargs ps -p
    echo ""
    exit 1
fi

# Step 1: Setup fast drive
echo ""
echo "=== Step 1: Setting up fast drive storage ==="
./01-setup-fast.sh

# Step 2: Optimize cache (optional)
echo ""
echo "=== Step 2: Cache optimization (optional) ==="
read -p "Move cache directories to tmpfs (RAM) for maximum performance? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./02-optimize-cache.sh
else
    echo "Skipping cache optimization"
fi

# Step 3: Verify
echo ""
echo "=== Step 3: Verifying changes ==="
./03-verify.sh

echo ""
echo "=========================================="
echo "Optimization Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "- Start Cursor IDE to verify performance improvement"
echo "- Run './03-verify.sh' anytime to check optimization status"
echo "- Cache data on tmpfs will be cleared on reboot (this is normal)"
echo ""
echo "If you need to rollback:"
echo "- Check backup directory: $SCRIPT_DIR/backup/cursor/"
echo "- Remove symlinks and restore from backup if needed"
