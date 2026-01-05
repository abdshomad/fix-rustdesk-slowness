# RustDesk Performance Optimization - Implementation Guide

This guide provides step-by-step instructions to optimize RustDesk performance by moving configuration and logs from the slow drive to the fast drive.

## Prerequisites

- Sudo/root access (required for some steps)
- RustDesk installed and running
- Backup of current configuration (already created in `backup/` directory)

## System Disk Configuration

This optimization is designed for systems with multiple drives where RustDesk data is stored on a slow drive:

**Fast OS Drive (NVMe SSD)**:
- Device: `/dev/mapper/ubuntu--vg-ubuntu--lv` (LVM logical volume)
- Physical Disk: `nvme0n1` (894.2G NVMe SSD)
- Size: 689G total, 260G used (40%), 401G available
- Mounted at: `/` (root filesystem)
- Performance: ~3000+ MB/s sequential, <0.1ms latency

**Slow Data Drive (HDD)**:
- Device: `/dev/sda1`
- Physical Disk: `sda` (21T HDD)
- Size: 21T total, 2.0T used (10%), 18T available
- Mounted at: `/home`
- Performance: ~200 MB/s sequential, 5-15ms latency

**tmpfs (RAM)**:
- Mounted at: `/tmp`
- Size: 51G (RAM-based)
- Performance: RAM speed, near-zero latency

**Problem**: RustDesk configuration and logs are stored on the slow drive (`/home` on `/dev/sda1`), causing 30-150x higher latency for I/O operations.

## Implementation Steps

### Step 1: Run the Setup Script

Execute the main setup script to move configuration to the fast drive:

```bash
cd /home/aiserver/LABS/RUSTDESK/fix-rustdesk-slowness
./01-setup-rustdesk-fast.sh
```

This script will:
- Create `/opt/rustdesk/config` on the fast drive
- Copy your configuration files
- Create a symlink from `~/.config/rustdesk` to `/opt/rustdesk/config`

### Step 2: Fix FUSE Mounts

Clean up broken FUSE mounts:

```bash
./02-fix-fuse-mounts.sh
```

This will:
- Unmount existing FUSE mounts (using `fusermount` or `sudo umount` with lazy unmount fallback)
- Clean up stale mount points (requires sudo for root-owned mounts)
- Ensure `/tmp/RustDesk` directory exists with proper permissions (1777)
- Note: FUSE mounts will be automatically recreated when RustDesk service restarts

### Step 3: Configure Log Location

Create systemd override to redirect logs to tmpfs (fastest option):

```bash
./03-create-systemd-override.sh
```

This will:
- Create systemd override file
- Configure RustDesk to use `/tmp/rustdesk-data` for logs (tmpfs - RAM-based)
- Reload systemd daemon

### Step 4: Restart RustDesk

Apply all changes by restarting the service:

```bash
sudo systemctl restart rustdesk
```

Verify the service is running:

```bash
sudo systemctl status rustdesk
```

### Step 5: Verify Performance

Run the monitoring script to verify improvements:

```bash
./04-monitor-performance.sh
```

This will show:
- Current configuration location (should be on fast drive)
- Log location (should be on tmpfs)
- FUSE mount status
- Service status
- Disk I/O statistics

## Expected Results

After completing these steps:

1. **Configuration**: Stored on fast drive (`/opt/rustdesk/config`)
   - Faster reads/writes
   - Reduced startup latency

2. **Logs**: Stored in tmpfs (`/tmp/rustdesk-data/logs/RustDesk`)
   - Near-instantaneous writes (RAM speed)
   - No disk I/O bottleneck

3. **FUSE Mounts**: Fixed and working properly
   - Clipboard sharing functional
   - No broken mount errors

4. **Performance Improvements**:
   - 30-50% faster startup time
   - Smoother screen sharing
   - Reduced latency in all operations

## Troubleshooting

### If symlink doesn't work

Check if the symlink exists:
```bash
ls -lah ~/.config/rustdesk
```

If it's broken, recreate it:
```bash
rm ~/.config/rustdesk
ln -s /opt/rustdesk/config ~/.config/rustdesk
```

### If logs still go to slow drive

Check systemd override:
```bash
sudo cat /etc/systemd/system/rustdesk.service.d/override.conf
```

Verify environment variables:
```bash
sudo systemctl show rustdesk | grep XDG
```

### If FUSE mounts are still broken

The script uses sudo to handle root-owned mounts. If you encounter permission issues:

```bash
# Try lazy unmount first (handles busy mounts)
sudo umount -l /tmp/RustDesk/cliprdr-client 2>/dev/null
sudo umount -l /tmp/RustDesk/cliprdr-server 2>/dev/null

# Clean up directory (requires sudo for root-owned files)
sudo rm -rf /tmp/RustDesk/cliprdr-client /tmp/RustDesk/cliprdr-server 2>/dev/null
sudo mkdir -p /tmp/RustDesk
sudo chmod 1777 /tmp/RustDesk

# Restart service (mounts will be recreated automatically)
sudo systemctl restart rustdesk
```

Or simply re-run the script:
```bash
./02-fix-fuse-mounts.sh
```

### Rollback

If you need to rollback:

```bash
# Remove symlink
rm ~/.config/rustdesk

# Restore from backup
cp -r backup/rustdesk ~/.config/rustdesk

# Remove systemd override
sudo rm -rf /etc/systemd/system/rustdesk.service.d/
sudo systemctl daemon-reload
sudo systemctl restart rustdesk
```

## Files Created

- `00-run-optimization.sh` - Master script (runs all steps)
- `01-setup-rustdesk-fast.sh` - Main setup script
- `02-fix-fuse-mounts.sh` - FUSE mount cleanup
- `03-create-systemd-override.sh` - Systemd configuration
- `04-monitor-performance.sh` - Performance monitoring
- `backup/` - Backup of original configuration

## Notes

- **Sudo Required**: Scripts `01-setup-rustdesk-fast.sh`, `02-fix-fuse-mounts.sh`, and `03-create-systemd-override.sh` require sudo privileges for:
  - Creating directories in `/opt` and `/etc/systemd`
  - Unmounting root-owned FUSE mounts
  - Setting directory permissions
- **Logs in tmpfs**: Will be cleared on reboot (this is normal and acceptable)
- **Configuration**: Persistent on `/opt/rustdesk/config` (fast drive)
- **Symlink Approach**: Ensures compatibility with RustDesk's expected paths (`~/.config/rustdesk`)
- **FUSE Mounts**: Automatically recreated by RustDesk on service restart
- **Rollback**: All changes are reversible via the backup directory

