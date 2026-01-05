# Cursor IDE Performance Optimization

This project contains scripts and documentation to optimize Cursor IDE performance by moving configuration, cache, and agent data from a slow drive to a fast drive.

## Problem

Cursor IDE was experiencing slow performance (especially startup, extension loading, and workspace operations) because:
- Configuration files were stored on slow drive (`/dev/sda1` mounted at `/home`)
- Cache files were written to slow drive
- Cursor agent data was on slow drive
- Large globalStorage (2.4GB) on slow drive delayed extension loading

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

**Performance Impact**: The slow drive has 30-150x higher latency than the fast drive, causing significant I/O bottlenecks for Cursor IDE operations.

## Solution

Move Cursor IDE data to fast drive:
- **Configuration**: `/opt/cursor/config` (fast drive) with symlink from `~/.config/Cursor`
- **Cursor Agent**: `/opt/cursor/cursor-agent` (fast drive) with symlink from `~/.local/share/cursor-agent`
- **Cache (optional)**: `/tmp/cursor-cache` (tmpfs - RAM-based, fastest)

## Quick Start

Run the master optimization script:

```bash
cd /home/aiserver/LABS/RUSTDESK/fix-rustdesk-is-slowness/fix-cursor-slowness
./00-run-optimization.sh
```

This will execute all optimization steps automatically.

**IMPORTANT**: Close Cursor IDE completely before running the optimization scripts!

## Files

### Scripts

- **`00-run-optimization.sh`** - Master script that runs all optimization steps
- **`01-setup-fast.sh`** - Moves configuration and agent to fast drive
- **`02-optimize-cache.sh`** - Optionally moves cache to tmpfs (RAM)
- **`03-verify.sh`** - Verifies optimization and shows performance metrics

### Documentation

- **`ANALYSIS.md`** - Detailed analysis of the performance issue
- **`README.md`** - This file

### Backup

- **`backup/cursor/`** - Backup of original Cursor configuration and agent data

## Manual Steps

If you prefer to run steps individually:

1. **Close Cursor IDE completely** (check with `pgrep -x cursor`)

2. **Setup fast drive storage:**
   ```bash
   ./01-setup-fast.sh
   ```

3. **Optionally optimize cache (recommended for best performance):**
   ```bash
   ./02-optimize-cache.sh
   ```

4. **Start Cursor IDE** to apply changes

5. **Verify changes:**
   ```bash
   ./03-verify.sh
   ```

## Expected Results

After optimization:
- ✅ Configuration on fast drive (30-50% faster reads)
- ✅ Cursor agent on fast drive (faster agent operations)
- ✅ Cache in tmpfs (RAM speed writes, if cache optimization enabled)
- ✅ Improved startup time
- ✅ Faster extension loading
- ✅ Improved overall IDE responsiveness

## Troubleshooting

### If symlink doesn't work

Check if the symlink exists:
```bash
ls -lah ~/.config/Cursor
ls -lah ~/.local/share/cursor-agent
```

If broken, the setup script will handle it automatically, or you can recreate:
```bash
rm ~/.config/Cursor
ln -s /opt/cursor/config ~/.config/Cursor

rm ~/.local/share/cursor-agent
ln -s /opt/cursor/cursor-agent ~/.local/share/cursor-agent
```

### If Cursor won't start after optimization

1. Check that symlinks are correct:
   ```bash
   readlink ~/.config/Cursor
   readlink ~/.local/share/cursor-agent
   ```

2. Verify permissions:
   ```bash
   ls -lah /opt/cursor/
   ```

3. Check Cursor logs:
   ```bash
   cat ~/.config/Cursor/logs/*/window1/output_*/cursor*.log | tail -50
   ```

### If cache optimization causes issues

Cache on tmpfs is cleared on reboot. If you experience issues:

1. Remove cache symlinks:
   ```bash
   rm ~/.config/Cursor/Cache
   rm ~/.config/Cursor/CachedData
   rm ~/.config/Cursor/WebStorage
   # etc.
   ```

2. Restart Cursor IDE (it will recreate cache directories)

3. Optionally restore from backup if needed

### Rollback

To rollback changes:

```bash
# Remove symlinks
rm ~/.config/Cursor
rm ~/.local/share/cursor-agent

# Restore from backup
cp -r backup/cursor/config ~/.config/Cursor
cp -r backup/cursor/cursor-agent ~/.local/share/cursor-agent

# Restart Cursor IDE
```

## Notes

- **Sudo Required**: Scripts `01-setup-fast.sh` and `02-optimize-cache.sh` require sudo privileges for:
  - Creating directories in `/opt`
  - Setting directory permissions
- **Cursor Must Be Closed**: All optimization scripts check if Cursor is running and will warn/abort if it is
- **Cache in tmpfs**: Cleared on reboot (normal behavior, acceptable trade-off for performance)
- **Configuration**: Persistent on `/opt/cursor/config` (fast drive)
- **Symlink Approach**: Ensures compatibility with Cursor's expected paths
- **Backup**: Original configuration is backed up in `backup/cursor/` directory for rollback

## Performance Metrics

### Before Optimization
- Configuration: `~/.config/Cursor` on `/dev/sda1` (slow HDD)
- Agent: `~/.local/share/cursor-agent` on `/dev/sda1` (slow HDD)
- Cache: Various cache directories on `/dev/sda1` (slow HDD)
- Latency: 5-15ms per I/O operation

### After Optimization
- Configuration: `/opt/cursor/config` on NVMe SSD
- Agent: `/opt/cursor/cursor-agent` on NVMe SSD
- Cache: `/tmp/cursor-cache` on tmpfs (RAM)
- Latency: <0.1ms per I/O operation (30-150x improvement)

## Related Projects

- **`fix-rustdesk-slowness/`** - Similar optimization for RustDesk remote desktop application
