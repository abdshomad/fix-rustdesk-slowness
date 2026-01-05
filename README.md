# Performance Optimization Projects

This repository contains optimization scripts and documentation for improving application performance by moving data from slow drives to fast drives.

## Overview

Both projects address the same underlying issue: applications experiencing slow performance because their data (configuration, cache, logs) is stored on a slow HDD drive (`/dev/sda1` mounted at `/home`) instead of the fast NVMe SSD drive.

### System Configuration

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

**Performance Impact**: The slow drive has **30-150x higher latency** than the fast drive, causing significant I/O bottlenecks.

## Projects

### 1. RustDesk Performance Optimization

Optimizes RustDesk remote desktop application performance.

**Location**: [`fix-rustdesk-slowness/`](fix-rustdesk-slowness/)

**Problem**: RustDesk was experiencing slow screen sharing and general operations because configuration and logs were stored on the slow drive.

**Solution**: 
- Moves configuration to `/opt/rustdesk/config` (fast drive)
- Moves logs to `/tmp/rustdesk-data/logs/RustDesk` (tmpfs - RAM-based)

**Quick Start**:
```bash
cd fix-rustdesk-slowness
./00-run-optimization.sh
```

**See**: [`fix-rustdesk-slowness/README.md`](fix-rustdesk-slowness/README.md) for detailed documentation.

---

### 2. Cursor IDE Performance Optimization

Optimizes Cursor IDE performance for faster startup, extension loading, and workspace operations.

**Location**: [`fix-cursor-slowness/`](fix-cursor-slowness/)

**Problem**: Cursor IDE was experiencing slow startup, extension loading, and workspace operations because configuration (4.0GB), cache, and agent data were stored on the slow drive.

**Solution**:
- Moves configuration to `/opt/cursor/config` (fast drive)
- Moves cursor-agent to `/opt/cursor/cursor-agent` (fast drive)
- Optionally moves cache to `/tmp/cursor-cache` (tmpfs - RAM-based)

**Quick Start**:
```bash
cd fix-cursor-slowness
./00-run-optimization.sh
```

**IMPORTANT**: Close Cursor IDE completely before running the optimization scripts!

**See**: [`fix-cursor-slowness/README.md`](fix-cursor-slowness/README.md) for detailed documentation.

## Repository Structure

```
.
├── README.md                    # This file
├── fix-rustdesk-slowness/       # RustDesk optimization
│   ├── 00-run-optimization.sh
│   ├── 01-setup-rustdesk-fast.sh
│   ├── 02-fix-fuse-mounts.sh
│   ├── 03-create-systemd-override.sh
│   ├── 04-monitor-performance.sh
│   ├── ANALYSIS.md
│   ├── IMPLEMENTATION.md
│   ├── README.md
│   └── STEPS.md
└── fix-cursor-slowness/         # Cursor IDE optimization
    ├── 00-run-optimization.sh
    ├── 01-setup-fast.sh
    ├── 02-optimize-cache.sh
    ├── 03-verify.sh
    ├── ANALYSIS.md
    └── README.md
```

## Common Approach

Both projects follow the same optimization strategy:

1. **Identify slow data locations** - Configuration, cache, logs on slow drive
2. **Create fast drive storage** - Set up directories on `/opt` (fast drive)
3. **Move data** - Copy data to fast drive locations
4. **Create symlinks** - Maintain compatibility with expected paths
5. **Optional cache optimization** - Move cache to tmpfs (RAM) for maximum performance
6. **Verify** - Check that optimizations are working correctly

## Requirements

- **Sudo privileges** - Required for creating directories in `/opt` and setting permissions
- **Application must be closed** - Especially important for Cursor IDE
- **Backup created** - All scripts create backups before making changes

## Expected Performance Improvements

After optimization:
- **30-50% faster startup time** (config reads from fast drive)
- **Reduced latency** for all operations
- **Faster cache operations** (if using tmpfs)
- **Improved overall responsiveness**

## Git Branches

- **`main`** - Original repository state
- **`fix-cursor-slowness`** - Branch with Cursor IDE optimization (includes reorganized structure)

## Notes

- All scripts include safety checks and backup mechanisms
- Symlinks ensure compatibility with application expectations
- Cache on tmpfs is cleared on reboot (normal behavior)
- Configuration on fast drive is persistent
- Both projects can be used independently

## Troubleshooting

For project-specific troubleshooting, see:
- RustDesk: [`fix-rustdesk-slowness/README.md`](fix-rustdesk-slowness/README.md)
- Cursor IDE: [`fix-cursor-slowness/README.md`](fix-cursor-slowness/README.md)

## License

This repository contains optimization scripts and documentation. Use at your own risk. Always backup your data before running optimization scripts.
