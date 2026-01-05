#!/bin/bash
# Monitor RustDesk disk I/O performance

echo "=== RustDesk Performance Monitoring ==="
echo ""

# Check where config is located
echo "1. Configuration Location:"
if [ -L "$HOME/.config/rustdesk" ]; then
    REAL_PATH=$(readlink -f "$HOME/.config/rustdesk")
    echo "   Symlink: $HOME/.config/rustdesk -> $REAL_PATH"
    DF_OUTPUT=$(df -h "$REAL_PATH" 2>/dev/null | tail -1)
    echo "   Filesystem: $DF_OUTPUT"
else
    echo "   Direct: $HOME/.config/rustdesk"
    DF_OUTPUT=$(df -h "$HOME/.config/rustdesk" 2>/dev/null | tail -1)
    echo "   Filesystem: $DF_OUTPUT"
fi

echo ""

# Check log location
echo "2. Log Location:"
if [ -d "$HOME/.local/share/logs/RustDesk" ]; then
    DF_OUTPUT=$(df -h "$HOME/.local/share/logs/RustDesk" 2>/dev/null | tail -1)
    echo "   Current: $HOME/.local/share/logs/RustDesk"
    echo "   Filesystem: $DF_OUTPUT"
else
    echo "   Log directory not found at default location"
fi

# Check tmpfs log location
if [ -d "/tmp/rustdesk-data/logs/RustDesk" ]; then
    DF_OUTPUT=$(df -h "/tmp/rustdesk-data/logs/RustDesk" 2>/dev/null | tail -1)
    echo "   tmpfs location: /tmp/rustdesk-data/logs/RustDesk"
    echo "   Filesystem: $DF_OUTPUT"
fi

echo ""

# Check FUSE mounts
echo "3. FUSE Mounts:"
mount | grep -i rustdesk || echo "   No RustDesk FUSE mounts found"

echo ""

# Check RustDesk service status
echo "4. RustDesk Service Status:"
systemctl is-active rustdesk >/dev/null 2>&1 && echo "   Status: Active" || echo "   Status: Inactive"
systemctl is-enabled rustdesk >/dev/null 2>&1 && echo "   Enabled: Yes" || echo "   Enabled: No"

echo ""

# Disk I/O stats (if iostat is available)
echo "5. Disk I/O Statistics (last 5 seconds):"
if command -v iostat >/dev/null 2>&1; then
    iostat -x 1 2 2>/dev/null | tail -n +4 || echo "   iostat not available or requires sudo"
else
    echo "   iostat not installed (install sysstat package)"
fi

echo ""

# Check for broken mounts
echo "6. Checking for broken mounts:"
if mountpoint -q /tmp/RustDesk/cliprdr-client 2>/dev/null; then
    if ! ls /tmp/RustDesk/cliprdr-client >/dev/null 2>&1; then
        echo "   WARNING: Broken mount detected at /tmp/RustDesk/cliprdr-client"
    else
        echo "   /tmp/RustDesk/cliprdr-client: OK"
    fi
else
    echo "   /tmp/RustDesk/cliprdr-client: Not mounted"
fi

if mountpoint -q /tmp/RustDesk/cliprdr-server 2>/dev/null; then
    if ! ls /tmp/RustDesk/cliprdr-server >/dev/null 2>&1; then
        echo "   WARNING: Broken mount detected at /tmp/RustDesk/cliprdr-server"
    else
        echo "   /tmp/RustDesk/cliprdr-server: OK"
    fi
else
    echo "   /tmp/RustDesk/cliprdr-server: Not mounted"
fi

echo ""
echo "=== Monitoring Complete ==="

