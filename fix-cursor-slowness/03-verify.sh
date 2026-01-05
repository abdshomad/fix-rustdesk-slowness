#!/bin/bash
# Verify Cursor IDE optimization and show performance metrics

echo "=========================================="
echo "Cursor IDE Optimization Verification"
echo "=========================================="
echo ""

# Check if config is on fast drive
echo "=== Configuration Location ==="
if [ -L "$HOME/.config/Cursor" ]; then
    LINK_TARGET=$(readlink "$HOME/.config/Cursor")
    echo "✓ ~/.config/Cursor is a symlink"
    echo "  Points to: $LINK_TARGET"
    
    if [[ "$LINK_TARGET" == "/opt/cursor/config" ]]; then
        echo "  ✓ On fast drive (/opt)"
        # Check which drive /opt is on
        OPT_DEVICE=$(df /opt | tail -1 | awk '{print $1}')
        echo "  Device: $OPT_DEVICE"
        df -h /opt | grep -E "(Filesystem|/opt)"
    else
        echo "  ⚠ Not pointing to expected location"
    fi
else
    if [ -d "$HOME/.config/Cursor" ]; then
        echo "⚠ ~/.config/Cursor is a directory (not symlink)"
        CONFIG_DEVICE=$(df "$HOME/.config/Cursor" | tail -1 | awk '{print $1}')
        echo "  Device: $CONFIG_DEVICE"
        if [[ "$CONFIG_DEVICE" == "/dev/sda1" ]]; then
            echo "  ⚠ Still on slow drive!"
        fi
    else
        echo "✗ ~/.config/Cursor not found"
    fi
fi

echo ""

# Check cursor-agent location
echo "=== Cursor Agent Location ==="
if [ -L "$HOME/.local/share/cursor-agent" ]; then
    LINK_TARGET=$(readlink "$HOME/.local/share/cursor-agent")
    echo "✓ ~/.local/share/cursor-agent is a symlink"
    echo "  Points to: $LINK_TARGET"
    
    if [[ "$LINK_TARGET" == "/opt/cursor/cursor-agent" ]]; then
        echo "  ✓ On fast drive (/opt)"
    else
        echo "  ⚠ Not pointing to expected location"
    fi
else
    if [ -d "$HOME/.local/share/cursor-agent" ]; then
        echo "⚠ ~/.local/share/cursor-agent is a directory (not symlink)"
        AGENT_DEVICE=$(df "$HOME/.local/share/cursor-agent" | tail -1 | awk '{print $1}')
        echo "  Device: $AGENT_DEVICE"
        if [[ "$AGENT_DEVICE" == "/dev/sda1" ]]; then
            echo "  ⚠ Still on slow drive!"
        fi
    else
        echo "✗ ~/.local/share/cursor-agent not found"
    fi
fi

echo ""

# Check cache locations
echo "=== Cache Locations ==="
CURSOR_CONFIG="/opt/cursor/config"
if [ -d "$CURSOR_CONFIG" ] || [ -L "$HOME/.config/Cursor" ]; then
    if [ -L "$HOME/.config/Cursor" ]; then
        ACTUAL_CONFIG=$(readlink -f "$HOME/.config/Cursor")
    else
        ACTUAL_CONFIG="$HOME/.config/Cursor"
    fi
    
    CACHE_DIRS=("Cache" "CachedData" "WebStorage" "Code Cache")
    CACHE_ON_TMPFS=0
    CACHE_ON_SLOW=0
    
    for CACHE_NAME in "${CACHE_DIRS[@]}"; do
        CACHE_PATH="$ACTUAL_CONFIG/$CACHE_NAME"
        if [ -L "$CACHE_PATH" ]; then
            LINK_TARGET=$(readlink "$CACHE_PATH")
            if [[ "$LINK_TARGET" == /tmp/cursor-cache* ]]; then
                echo "✓ $CACHE_NAME -> tmpfs (RAM)"
                CACHE_ON_TMPFS=$((CACHE_ON_TMPFS + 1))
            else
                echo "  $CACHE_NAME -> $LINK_TARGET"
            fi
        elif [ -d "$CACHE_PATH" ]; then
            CACHE_DEVICE=$(df "$CACHE_PATH" | tail -1 | awk '{print $1}')
            if [[ "$CACHE_DEVICE" == "/dev/sda1" ]]; then
                echo "⚠ $CACHE_NAME on slow drive"
                CACHE_ON_SLOW=$((CACHE_ON_SLOW + 1))
            elif [[ "$CACHE_DEVICE" == "tmpfs" ]]; then
                echo "✓ $CACHE_NAME on tmpfs (RAM)"
                CACHE_ON_TMPFS=$((CACHE_ON_TMPFS + 1))
            else
                echo "  $CACHE_NAME on $CACHE_DEVICE"
            fi
        fi
    done
    
    if [ $CACHE_ON_TMPFS -gt 0 ]; then
        echo ""
        echo "Cache optimization: $CACHE_ON_TMPFS cache directories on tmpfs"
    fi
    if [ $CACHE_ON_SLOW -gt 0 ]; then
        echo ""
        echo "⚠ Warning: $CACHE_ON_SLOW cache directories still on slow drive"
        echo "  Consider running 02-optimize-cache.sh"
    fi
else
    echo "⚠ Cannot check cache locations (config not found)"
fi

echo ""

# Show disk usage
echo "=== Disk Usage ==="
echo "Fast drive (/opt):"
df -h /opt | grep -E "(Filesystem|/opt)"
echo ""
echo "Slow drive (/home):"
df -h /home | grep -E "(Filesystem|/home)"
echo ""
echo "tmpfs (/tmp):"
df -h /tmp | grep -E "(Filesystem|/tmp)"

echo ""

# Show Cursor data sizes
echo "=== Cursor Data Sizes ==="
if [ -d "/opt/cursor/config" ]; then
    echo "Config on fast drive:"
    du -sh /opt/cursor/config 2>/dev/null || echo "  Unable to determine size"
    echo ""
    echo "Largest directories:"
    du -sh /opt/cursor/config/* 2>/dev/null | sort -h | tail -5
fi

if [ -d "/opt/cursor/cursor-agent" ]; then
    echo ""
    echo "Cursor-agent on fast drive:"
    du -sh /opt/cursor/cursor-agent 2>/dev/null || echo "  Unable to determine size"
fi

if [ -d "/tmp/cursor-cache" ]; then
    echo ""
    echo "Cache on tmpfs:"
    du -sh /tmp/cursor-cache 2>/dev/null || echo "  Unable to determine size"
fi

echo ""

# Check if Cursor is running
echo "=== Cursor IDE Status ==="
if pgrep -x "cursor" > /dev/null; then
    echo "✓ Cursor IDE is running"
    echo "  Process count: $(pgrep -x cursor | wc -l)"
    echo ""
    echo "  Processes:"
    pgrep -x cursor | xargs ps -p -o pid,cmd --no-headers | head -3
else
    echo "Cursor IDE is not running"
fi

echo ""

# Performance summary
echo "=== Optimization Summary ==="
OPTIMIZED=0
WARNINGS=0

# Check config
if [ -L "$HOME/.config/Cursor" ] && [[ "$(readlink "$HOME/.config/Cursor")" == "/opt/cursor/config" ]]; then
    OPTIMIZED=$((OPTIMIZED + 1))
else
    WARNINGS=$((WARNINGS + 1))
fi

# Check agent
if [ -L "$HOME/.local/share/cursor-agent" ] && [[ "$(readlink "$HOME/.local/share/cursor-agent")" == "/opt/cursor/cursor-agent" ]]; then
    OPTIMIZED=$((OPTIMIZED + 1))
else
    WARNINGS=$((WARNINGS + 1))
fi

# Check cache
if [ -L "$HOME/.config/Cursor/Cache" ] && [[ "$(readlink "$HOME/.config/Cursor/Cache")" == /tmp/cursor-cache* ]]; then
    OPTIMIZED=$((OPTIMIZED + 1))
fi

echo "Optimized components: $OPTIMIZED"
if [ $WARNINGS -gt 0 ]; then
    echo "⚠ Items needing attention: $WARNINGS"
    echo ""
    echo "Recommendations:"
    if [ ! -L "$HOME/.config/Cursor" ] || [[ "$(readlink "$HOME/.config/Cursor")" != "/opt/cursor/config" ]]; then
        echo "  - Run 01-setup-fast.sh to move config to fast drive"
    fi
    if [ ! -L "$HOME/.local/share/cursor-agent" ] || [[ "$(readlink "$HOME/.local/share/cursor-agent")" != "/opt/cursor/cursor-agent" ]]; then
        echo "  - Run 01-setup-fast.sh to move cursor-agent to fast drive"
    fi
    if [ ! -L "$HOME/.config/Cursor/Cache" ] || [[ "$(readlink "$HOME/.config/Cursor/Cache") != /tmp/cursor-cache* ]]; then
        echo "  - Run 02-optimize-cache.sh to move cache to tmpfs"
    fi
else
    echo "✓ All optimizations applied successfully!"
fi

echo ""
echo "=========================================="
