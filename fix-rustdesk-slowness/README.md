# RustDesk Performance Optimization

This project contains scripts and documentation to optimize RustDesk performance by moving configuration and logs from a slow drive to a fast drive.

## Problem

RustDesk was experiencing slow performance (especially screen sharing) because:
- Configuration files were stored on slow drive (`/dev/sda1` mounted at `/home`)
- Log files were written to slow drive
- Broken FUSE mounts causing additional issues

## System Disk Configuration

### Current Disk Setup

**Fast OS Drive (NVMe SSD)**:
- Device: `/dev/mapper/ubuntu--vg-ubuntu--lv` (LVM logical volume)
- Physical Disk: `nvme0n1` (894.2G NVMe SSD)
- Size: 689G total, 260G used (40%), 401G available
- Mounted at: `/` (root filesystem)
- Contains: OS, system binaries, `/opt`, `/var`
- Performance: ~3000+ MB/s sequential, <0.1ms latency

**Slow Data Drive (HDD)**:
- Device: `/dev/sda1`
- Physical Disk: `sda` (21T HDD)
- Size: 21T total, 2.0T used (10%), 18T available
- Mounted at: `/home`
- Contains: User data, Docker images, application data
- Performance: ~200 MB/s sequential, 5-15ms latency

**tmpfs (RAM)**:
- Mounted at: `/tmp`
- Size: 51G (RAM-based)
- Performance: RAM speed, near-zero latency

**Performance Impact**: The slow drive has 30-150x higher latency than the fast drive, causing significant I/O bottlenecks for RustDesk operations.

## Solution

Move RustDesk data to fast drive:
- **Configuration**: `/opt/rustdesk/config` (fast drive) with symlink from `~/.config/rustdesk`
- **Logs**: `/tmp/rustdesk-data/logs/RustDesk` (tmpfs - RAM-based, fastest)

## Quick Start

Run the master optimization script:

```bash
cd /home/aiserver/LABS/RUSTDESK/fix-rustdesk-slowness
./00-run-optimization.sh
```

This will execute all optimization steps automatically.

## Files

### Scripts

- **`00-run-optimization.sh`** - Master script that runs all optimization steps
- **`01-setup-rustdesk-fast.sh`** - Moves configuration to fast drive
- **`02-fix-fuse-mounts.sh`** - Cleans up broken FUSE mounts
- **`03-create-systemd-override.sh`** - Configures log location via systemd override
- **`04-monitor-performance.sh`** - Monitors and verifies performance improvements

### Documentation

- **`ANALYSIS.md`** - Detailed analysis of the performance issue
- **`IMPLEMENTATION.md`** - Step-by-step implementation guide
- **`README.md`** - This file

### Backup

- **`backup/`** - Backup of original RustDesk configuration

## Manual Steps

If you prefer to run steps individually:

1. **Setup fast drive storage:**
   ```bash
   ./01-setup-rustdesk-fast.sh
   ```

2. **Fix FUSE mounts:**
   ```bash
   ./02-fix-fuse-mounts.sh
   ```

3. **Configure log location:**
   ```bash
   ./03-create-systemd-override.sh
   ```

4. **Restart RustDesk:**
   ```bash
   sudo systemctl restart rustdesk
   ```

5. **Verify changes:**
   ```bash
   ./04-monitor-performance.sh
   ```

## Expected Results

After optimization:
- ✅ Configuration on fast drive (30-50% faster reads)
- ✅ Logs in tmpfs (RAM speed writes)
- ✅ Fixed FUSE mounts
- ✅ Improved screen sharing performance
- ✅ Reduced latency in all operations

## Troubleshooting

See `IMPLEMENTATION.md` for detailed troubleshooting steps.

## Rollback

To rollback changes:

```bash
# Remove symlink and restore backup
rm ~/.config/rustdesk
cp -r backup/rustdesk ~/.config/rustdesk

# Remove systemd override
sudo rm -rf /etc/systemd/system/rustdesk.service.d/
sudo systemctl daemon-reload
sudo systemctl restart rustdesk
```

## Notes

- **Sudo Required**: Scripts `01-setup-rustdesk-fast.sh`, `02-fix-fuse-mounts.sh`, and `03-create-systemd-override.sh` require sudo privileges for:
  - Creating directories in `/opt` and `/etc/systemd`
  - Unmounting root-owned FUSE mounts
  - Setting directory permissions
- **FUSE Mounts**: The `02-fix-fuse-mounts.sh` script uses multiple unmount strategies (fusermount, lazy unmount, force unmount) to handle busy or root-owned mounts. Mounts are automatically recreated by RustDesk on service restart.
- **Logs in tmpfs**: Cleared on reboot (normal behavior, acceptable trade-off for performance)
- **Configuration**: Persistent on `/opt/rustdesk/config` (fast drive)
- **Symlink**: `~/.config/rustdesk` symlinks to `/opt/rustdesk/config` for compatibility
- **Backup**: Original configuration is backed up in `backup/` directory for rollback

