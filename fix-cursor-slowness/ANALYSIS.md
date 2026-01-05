# Cursor IDE Performance Analysis

## Problem Summary

Cursor IDE is experiencing slow performance, particularly with startup, extension loading, workspace operations, and general responsiveness. The user suspects this may be due to data storage on a slow drive.

## System Configuration

### Disk Layout

#### Fast OS Drive (NVMe SSD)
- **Device**: `/dev/mapper/ubuntu--vg-ubuntu--lv` (LVM logical volume)
- **Physical Disk**: `nvme0n1` (894.2G NVMe SSD)
  - Partition 1: `nvme0n1p1` (1G) - `/boot/efi` (vfat)
  - Partition 2: `nvme0n1p2` (2G) - `/boot` (ext4)
  - Partition 3: `nvme0n1p3` (891.1G) - LVM2_member
- **Size**: 689G total
- **Used**: 260G (40% used)
- **Available**: 401G
- **Filesystem**: LVM on ext4
- **Mounted at**: `/` (root filesystem)
- **Contains**: Operating system, system binaries, `/opt`, `/var`, `/tmp` (tmpfs)
- **Performance**: NVMe SSD - ~3000+ MB/s sequential, <0.1ms latency

#### Slow Data Drive (HDD)
- **Device**: `/dev/sda1`
- **Physical Disk**: `sda` (21T HDD)
- **Size**: 21T total
- **Used**: 2.0T (10% used)
- **Available**: 18T
- **Filesystem**: ext4
- **Mounted at**: `/home`
- **Contains**: User home directories, Docker images, application data
- **Performance**: HDD - ~200 MB/s sequential, 5-15ms latency

#### tmpfs (RAM-based)
- **Mounted at**: `/tmp`
- **Size**: 51G (varies based on RAM)
- **Used**: Minimal
- **Performance**: RAM speed - fastest possible, near-zero latency

### Cursor IDE Installation Details

**Installation Type**: System package (`.deb` installation)
- Binary location: `/usr/bin/cursor`
- Installation path: `/usr/share/cursor/`
- Process: Electron-based application

**Current Data Locations** (all on slow drive `/home`):

#### Configuration Directory: `~/.config/Cursor` (4.0GB total)
- **`User/globalStorage`**: 2.4GB (largest component)
  - Extension data and state
  - Workspace storage metadata
  - Extension settings and caches
  - Frequently accessed during IDE operations
  
- **`WebStorage`**: 915MB
  - Browser cache and storage
  - Session data
  - Frequently written during browsing/extension operations
  
- **`User/workspaceStorage`**: 148MB
  - Workspace-specific data
  - Project state and metadata
  - Accessed on every workspace operation
  
- **`User/History`**: 63MB
  - File history and navigation data
  - Accessed during file operations
  
- **`CachedData`**: 246MB
  - Application cache
  - Frequently read/written
  
- **`Partitions`**: 114MB
  - Browser partition data
  - Multiple partitions for different contexts
  
- **`Cache`**: 96MB
  - General application cache
  - Frequently accessed
  
- **`logs`**: 1.2MB (191 log files)
  - Application and extension logs
  - Continuously written during IDE usage

#### Agent Directory: `~/.local/share/cursor-agent` (171MB)
- Agent binaries and data
- Version-specific agent files
- Accessed during AI/agent operations

## Root Cause Analysis

### Primary Issues

1. **Configuration Files on Slow Drive**
   - All Cursor IDE configuration files are stored in `~/.config/Cursor/` which resides on `/dev/sda1` (slow drive)
   - Every configuration read/write operation hits the slow drive
   - This affects startup time, extension loading, and runtime configuration updates
   - The 2.4GB `globalStorage` directory is frequently accessed for extension data

2. **Cache Files on Slow Drive**
   - Multiple cache directories (`Cache`, `CachedData`, `WebStorage`) are on the slow drive
   - Frequent cache reads/writes during IDE operations create I/O bottlenecks
   - Browser cache operations (WebStorage) are particularly slow
   - 915MB of WebStorage indicates heavy browser-related caching

3. **Workspace Storage on Slow Drive**
   - Workspace-specific data (148MB) is accessed frequently during project operations
   - File history (63MB) is read on every navigation operation
   - These operations compound the latency issues

4. **Log Files on Slow Drive**
   - 191 log files (1.2MB) are continuously written during IDE usage
   - Log writes create additional I/O overhead
   - While small in size, frequent writes add up

5. **Agent Data on Slow Drive**
   - Cursor agent binaries and data (171MB) are on the slow drive
   - Agent operations may be delayed by slow I/O

6. **I/O Latency Impact**
   - IDE operations require frequent I/O operations (reading config, writing cache, updating workspace state)
   - Slow drive I/O latency compounds these operations
   - Each operation (file open, extension load, workspace switch) may be delayed by slow disk access
   - The 30-150x latency difference significantly impacts user experience

## Performance Impact

### Measured Symptoms
- Slow IDE startup time
- Delayed extension loading
- Sluggish workspace operations
- Slow file navigation and history
- General unresponsiveness during operations
- Cache operations feel slow

### Technical Impact
- **Read Latency**: Configuration and cache reads from slow drive add latency to startup and operations
- **Write Latency**: Cache and log writes during active sessions create bottlenecks
- **I/O Contention**: Slow drive may be shared with Docker images and other data, causing contention
- **Extension Loading**: Large globalStorage (2.4GB) on slow drive delays extension initialization
- **Workspace Operations**: Frequent workspace storage access compounds latency issues

## Solution Strategy

### Option 1: Move to Fast Drive (Recommended)
Move Cursor IDE data directories to the fast OS drive:

**Advantages**:
- Fastest I/O performance
- Reduced latency for all operations
- Better IDE responsiveness
- Faster extension loading

**Implementation**:
- Move `~/.config/Cursor/` to `/opt/cursor/config/` (fast drive)
- Create symlink: `~/.config/Cursor` → `/opt/cursor/config`
- Move `~/.local/share/cursor-agent` to `/opt/cursor/cursor-agent/` (fast drive)
- Create symlink: `~/.local/share/cursor-agent` → `/opt/cursor/cursor-agent`

### Option 2: Use tmpfs for Cache
Configure cache directories to write to RAM-based tmpfs:

**Advantages**:
- Extremely fast cache operations (RAM speed)
- No disk wear
- Cache cleared on reboot (acceptable for most use cases)

**Implementation**:
- Create tmpfs mount or use `/tmp/cursor-cache`
- Symlink cache directories to tmpfs
- Keep configuration on fast drive

### Option 3: Hybrid Approach (Best Performance)
Combine both approaches:
- Config and workspace data on fast drive (persistent)
- Cache and temp data on tmpfs (fastest, temporary)

## Recommended Actions

1. **Immediate Fixes**:
   - Move configuration to fast drive
   - Move cursor-agent to fast drive
   - Optionally move cache to tmpfs

2. **Configuration Optimizations**:
   - Review Cursor settings for performance options
   - Consider disabling unnecessary extensions
   - Optimize workspace settings

3. **Monitoring**:
   - Measure I/O latency before/after changes
   - Monitor disk I/O during IDE operations
   - Track performance improvements

## Expected Performance Improvements

After implementing the solution:
- **Startup Time**: 30-50% faster (config reads from fast drive)
- **Extension Loading**: Significantly faster (globalStorage on fast drive)
- **Workspace Operations**: Reduced latency, smoother operations
- **Cache Operations**: Near-instantaneous (if using tmpfs)
- **Overall Responsiveness**: Noticeable improvement in all operations

## Technical Details

### Current Data Structure
```
~/.config/Cursor/
├── User/
│   ├── globalStorage/     (2.4GB - extension data)
│   ├── workspaceStorage/  (148MB - workspace data)
│   └── History/           (63MB - file history)
├── WebStorage/            (915MB - browser cache)
├── CachedData/            (246MB - app cache)
├── Partitions/            (114MB - browser partitions)
├── Cache/                 (96MB - general cache)
└── logs/                  (1.2MB - 191 log files)

~/.local/share/cursor-agent/  (171MB - agent binaries)
```

### Disk Performance Comparison

| Drive Type | Device | Size | Sequential Speed | Latency | Use Case |
|------------|--------|------|------------------|---------|----------|
| **NVMe SSD** | `/dev/mapper/ubuntu--vg-ubuntu--lv` | 689G | ~3000+ MB/s | <0.1ms | OS, system files, `/opt` |
| **HDD** | `/dev/sda1` | 21T | ~200 MB/s | 5-15ms | User data, `/home`, Docker |
| **tmpfs (RAM)** | `/tmp` | 51G | RAM speed | Near-zero | Temporary files, cache |

**Performance Impact**: The slow drive has **30-150x higher latency** than the fast drive, which significantly impacts frequent small I/O operations typical of IDE applications. Moving Cursor IDE data from the slow drive (`/home` on `/dev/sda1`) to the fast drive (`/opt` on `/dev/mapper/ubuntu--vg-ubuntu--lv`) or tmpfs (`/tmp`) eliminates this bottleneck.

## Conclusion

Yes, Cursor IDE is slow because critical data (config, cache, workspace storage, and agent) are stored on the slow drive (`/dev/sda1`). Moving these to the fast OS drive or tmpfs will significantly improve performance, especially for startup, extension loading, and workspace operations that require frequent I/O.

## Implementation Status

The optimization will be implemented with the following scripts (numbered in execution order):

- `00-run-optimization.sh` - Master script (runs all steps)
- `01-setup-fast.sh` - Moves configuration and agent to fast drive
- `02-optimize-cache.sh` - Optionally moves cache to tmpfs
- `03-verify.sh` - Verifies optimization

All scripts are ready to use. See `README.md` for detailed usage instructions.
