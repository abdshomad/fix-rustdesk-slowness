#!/bin/bash
# Create systemd override to use fast drive for logs

set -e

echo "=== Creating systemd override for RustDesk ==="

# Create override directory
sudo mkdir -p /etc/systemd/system/rustdesk.service.d/

# Create override file
sudo tee /etc/systemd/system/rustdesk.service.d/override.conf > /dev/null <<EOF
[Service]
# Redirect logs to tmpfs (fastest) or fast drive
# Using XDG_DATA_HOME to override default ~/.local/share location
Environment="XDG_DATA_HOME=/tmp/rustdesk-data"
Environment="XDG_CACHE_HOME=/tmp/rustdesk-cache"
# Ensure /tmp directories exist and are writable
ExecStartPre=/bin/mkdir -p /tmp/rustdesk-data/logs/RustDesk
ExecStartPre=/bin/mkdir -p /tmp/rustdesk-cache
ExecStartPre=/bin/chmod 1777 /tmp/rustdesk-data /tmp/rustdesk-cache
EOF

echo "Override file created at /etc/systemd/system/rustdesk.service.d/override.conf"
echo ""
echo "Contents:"
sudo cat /etc/systemd/system/rustdesk.service.d/override.conf

echo ""
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo ""
echo "=== Override created ==="
echo "To apply changes, restart RustDesk:"
echo "  sudo systemctl restart rustdesk"

