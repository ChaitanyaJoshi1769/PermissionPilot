# Performance Tuning Guide

Optimize PermissionPilot for your hardware, use case, and preferences.

---

## Overview

This guide covers:
- **Baseline Performance** - What to expect on different hardware
- **CPU Optimization** - Reducing CPU usage
- **Memory Optimization** - Reducing memory footprint
- **Detection Speed** - Making dialog detection faster
- **Hardware Profiles** - Configurations for different machines
- **Use Case Tuning** - Optimizations for specific scenarios
- **Benchmarking** - Measuring and comparing performance

---

## Baseline Performance

### Expected Performance (M1 MacBook Pro)

```
Idle State (no dialogs):
  CPU: 0.1-0.3%
  Memory: 80-95 MB
  Threads: 8-10
  Power: ~0.5W

Active Detection (dialog appears):
  CPU: 5-8% (peak)
  Memory: 100-120 MB
  Time to detect: 50-210 ms
  Time to return to idle: <2 seconds

Automation (button click):
  CPU: 8-12% (peak)
  Memory: 120-150 MB
  Time to execute: 200-500 ms
  Time to return to idle: <2 seconds
```

### Hardware Tiers

#### Tier 1: Apple Silicon (M1/M2/M3)
- **CPU:** Up to 8 cores
- **RAM:** 8GB minimum, 16GB+ recommended
- **Expected:** Excellent performance, <1% idle CPU
- **Configuration:** Balanced (default settings)

#### Tier 2: Intel MacBook Pro (2019+)
- **CPU:** 6-10 cores
- **RAM:** 16GB minimum recommended
- **Expected:** Good performance, <1-2% idle CPU
- **Configuration:** Slightly reduced polling interval

#### Tier 3: Older Intel Macs (2015-2018)
- **CPU:** 2-6 cores
- **RAM:** 8GB (tight), 16GB+ better
- **Expected:** Fair performance, 1-3% idle CPU
- **Configuration:** Aggressive optimization recommended

#### Tier 4: Mac Mini, iMac (various)
- **CPU:** Variable (4-10 cores)
- **RAM:** 8GB+ recommended
- **Expected:** Depends on year and config
- **Configuration:** Match to CPU cores

---

## CPU Optimization

### High CPU Usage (>5% idle)

**Step 1: Check what's consuming CPU**

```bash
# View top CPU consumers
top -o cpu -R -F

# Filter for PermissionPilot
top -o cpu -R -F | grep -i permission

# Expected: PermissionPilot <0.5% idle
```

**Step 2: Reduce polling frequency**

```bash
# Edit configuration
nano ~/Library/Application\ Support/PermissionPilot/config.json

# Find daemon section:
"daemon": {
  "polling_interval_ms": 500  // Change from 500 to 1000
}

# Slower polling = lower CPU but slower detection
# 250ms: aggressive (5-8% CPU spike)
# 500ms: balanced (default, 3-5% spike)
# 1000ms: conservative (1-2% spike)
```

**Step 3: Disable expensive features**

```bash
# Disable OCR (expensive for CPU)
"detection": {
  "ocr_enabled": false  // Use Accessibility API only
}

# Disable screenshots
"screenshots": {
  "capture_enabled": false  // No image capture
}

# Disable debug logging
"logging": {
  "debug_mode": false
}
```

**Step 4: Increase detection cache TTL**

```bash
# Cache detection results longer
"detection": {
  "detection_cache_ttl_seconds": 120  // Cache for 2 minutes
}

# Reduces re-detection frequency for same dialog
```

### CPU Profiles

**Performance Mode (Max speed, normal CPU):**
```json
{
  "daemon": {
    "polling_interval_ms": 250,
    "debounce_ms": 50
  },
  "detection": {
    "method": "hybrid",
    "confidence_threshold": 0.75
  },
  "automation": {
    "click_delay_ms": 50,
    "mouse_speed_ms": 50
  }
}
```

**Balanced Mode (Default):**
```json
{
  "daemon": {
    "polling_interval_ms": 500,
    "debounce_ms": 100
  },
  "detection": {
    "method": "hybrid",
    "confidence_threshold": 0.85
  },
  "automation": {
    "click_delay_ms": 150,
    "mouse_speed_ms": 100
  }
}
```

**Power Saver Mode (Low CPU, slower detection):**
```json
{
  "daemon": {
    "polling_interval_ms": 2000,
    "debounce_ms": 200
  },
  "detection": {
    "method": "accessibility_api",
    "ocr_enabled": false,
    "confidence_threshold": 0.95
  },
  "automation": {
    "click_delay_ms": 300,
    "mouse_speed_ms": 200
  }
}
```

---

## Memory Optimization

### High Memory Usage (>150MB idle)

**Step 1: Check memory usage**

```bash
# View memory details
ps aux | grep PermissionPilot

# Expected: ~85-100 MB

# Detailed memory breakdown
instruments -t "Allocations" -l 10 /Applications/PermissionPilot.app
```

**Step 2: Clear old data**

```bash
# Clear audit logs (< 30 days instead of 90)
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
DELETE FROM automation_events WHERE timestamp < datetime('now', '-30 days');
VACUUM;
EOF

# Check size before/after
du -sh ~/Library/Application\ Support/PermissionPilot/audit.db
```

**Step 3: Disable screenshots**

```bash
# Screenshots consume significant memory
"screenshots": {
  "capture_enabled": false  // Disables all screenshot storage
}

# Or reduce retention
"screenshots": {
  "retention_days": 1  // Delete after 1 day instead of 7
}

# Check screenshot directory size
du -sh ~/Library/Application\ Support/PermissionPilot/screenshots/
```

**Step 4: Reduce database cache**

```bash
# Smaller cache = less memory, slower queries
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
PRAGMA cache_size = -32000;  // 32MB instead of default 64MB
PRAGMA temp_store = OFF;     // Don't cache temporary data
EOF
```

### Memory Profiles

**Lightweight Profile (<80MB):**
```json
{
  "database": {
    "max_retention_days": 30,
    "auto_vacuum_enabled": true
  },
  "screenshots": {
    "capture_enabled": false
  },
  "logging": {
    "debug_mode": false
  }
}
```

**Balanced Profile (~100MB):**
```json
{
  "database": {
    "max_retention_days": 60
  },
  "screenshots": {
    "capture_enabled": false,
    "capture_for_ocr": true,
    "retention_days": 1
  }
}
```

**Full-Featured Profile (150-200MB):**
```json
{
  "database": {
    "max_retention_days": 90
  },
  "screenshots": {
    "capture_enabled": true,
    "retention_days": 7
  },
  "logging": {
    "debug_mode": true,
    "log_level": "debug"
  }
}
```

---

## Detection Speed Optimization

### Making Dialog Detection Faster

**Fastest Detection (<100ms):**

```json
{
  "detection": {
    "method": "accessibility_api",
    "ocr_enabled": false,
    "confidence_threshold": 0.80,
    "max_detection_retries": 1,
    "detection_cache_ttl_seconds": 30
  }
}
```

- Accessibility API only: 50-100ms
- No OCR fallback
- Lower confidence allows faster decisions
- Cached results reused frequently

**Balanced Speed (~200ms):**

```json
{
  "detection": {
    "method": "hybrid",
    "ocr_enabled": true,
    "confidence_threshold": 0.85,
    "max_detection_retries": 2,
    "detection_cache_ttl_seconds": 60
  }
}
```

- Primary: Accessibility API (50-100ms)
- Fallback: OCR (200-300ms if needed)
- Most dialogs detected within 100ms
- Some harder dialogs need OCR (200-300ms)

**Most Accurate (~300ms):**

```json
{
  "detection": {
    "method": "hybrid",
    "ocr_enabled": true,
    "ocr_fallback_enabled": true,
    "confidence_threshold": 0.95,
    "max_detection_retries": 3,
    "detection_cache_ttl_seconds": 120
  }
}
```

- Multiple retry attempts
- High confidence threshold requires thorough analysis
- Takes longer but more accurate
- Best for security-critical scenarios

---

## Use Case Tuning

### Heavy Dialog Volume (100+ dialogs/hour)

**Issue:** Many dialogs causing CPU spikes

**Solution:**

```json
{
  "daemon": {
    "polling_interval_ms": 250,
    "debounce_ms": 50
  },
  "detection": {
    "method": "accessibility_api",
    "ocr_enabled": false,
    "confidence_threshold": 0.80
  },
  "automation": {
    "click_delay_ms": 50
  },
  "database": {
    "max_retention_days": 30
  }
}
```

**Benefits:**
- Aggressive polling catches all dialogs
- Fast Accessibility API detection
- Lower confidence threshold for speed
- Reduced memory usage (30-day retention)

### Privacy Mode (Minimal activity)

**Issue:** Want to minimize CPU/memory even at cost of speed

**Solution:**

```json
{
  "daemon": {
    "polling_interval_ms": 5000,  // Check every 5 seconds
    "debounce_ms": 500
  },
  "detection": {
    "method": "accessibility_api",
    "ocr_enabled": false,
    "confidence_threshold": 0.95
  },
  "automation": {
    "enabled": false  // Manual only
  },
  "screenshots": {
    "capture_enabled": false
  },
  "logging": {
    "debug_mode": false
  }
}
```

**Results:**
- CPU: <0.1% (almost nothing)
- Memory: 50-60MB
- Dialogs detected manually or with 5s delay

### Development Mode (Maximum features)

**Issue:** Developer wants all features for testing/debugging

**Solution:**

```json
{
  "daemon": {
    "polling_interval_ms": 250
  },
  "detection": {
    "method": "hybrid",
    "ocr_enabled": true,
    "ocr_fallback_enabled": true,
    "confidence_threshold": 0.70
  },
  "screenshots": {
    "capture_enabled": true,
    "retention_days": 14
  },
  "logging": {
    "debug_mode": true,
    "log_level": "debug"
  }
}
```

**Features:**
- Fast detection (250ms polling)
- All detection methods enabled
- Screenshots for visual debugging
- Detailed logging

---

## Benchmarking

### Measure Your Performance

```bash
#!/bin/bash
# benchmark.sh - Measure PermissionPilot performance

echo "=== PermissionPilot Performance Benchmark ==="
echo "Time: $(date)"
echo ""

# 1. Get baseline
echo "Measuring baseline CPU/Memory (30 seconds)..."
(top -l 30 -s 1 | grep PermissionPilot | \
  awk '{sum1+=$3; sum2+=$4; count++} END {print "Avg CPU: " sum1/count "%, Avg Memory: " sum2/count "%"}')

# 2. Check detection time
echo ""
echo "Measuring detection performance..."
start_time=$(date +%s%N)
# ... trigger dialog ...
end_time=$(date +%s%N)
detection_ms=$(( (end_time - start_time) / 1000000 ))
echo "Detection time: ${detection_ms}ms"

# 3. Check memory growth (5 minute test)
echo ""
echo "Memory growth test (5 minutes)..."
INITIAL=$(ps aux | grep PermissionPilot | grep -v grep | awk '{print $6}')
sleep 300
FINAL=$(ps aux | grep PermissionPilot | grep -v grep | awk '{print $6}')
GROWTH=$(( FINAL - INITIAL ))
echo "Initial memory: ${INITIAL}MB"
echo "Final memory: ${FINAL}MB"
echo "Growth: ${GROWTH}MB"

# 4. Database stats
echo ""
echo "Database statistics..."
sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db << 'EOF'
SELECT 
  (SELECT COUNT(*) FROM automation_events) as total_events,
  (SELECT ROUND(((page_count * page_size) / 1024.0 / 1024.0), 2) 
   FROM pragma_page_count(), pragma_page_size()) as db_size_mb;
EOF

echo ""
echo "Benchmark complete!"
```

### Compare Configurations

```bash
#!/bin/bash
# compare-configs.sh - Compare performance of different configurations

CONFIGS=(
  "performance"
  "balanced"
  "power-saver"
)

for config in "${CONFIGS[@]}"; do
  echo "=== Testing $config configuration ==="
  
  # Copy config
  cp configs/$config.json ~/Library/Application\ Support/PermissionPilot/config.json
  
  # Restart daemon
  launchctl stop com.permissionpilot.daemon
  sleep 2
  launchctl start com.permissionpilot.daemon
  sleep 2
  
  # Measure for 60 seconds
  echo "CPU and Memory (average over 60 seconds):"
  (top -l 60 -s 1 | grep PermissionPilot | \
    awk '{sum1+=$3; sum2+=$4; count++} END {print "  CPU: " sum1/count "%, Memory: " sum2/count "%"}')
  
  echo ""
done
```

---

## Hardware-Specific Optimization

### M1/M2/M3 (Apple Silicon)

**Optimal Configuration:**
```json
{
  "daemon": {
    "polling_interval_ms": 300
  },
  "detection": {
    "method": "hybrid"
  }
}
```

**Results:**
- CPU: <0.3% idle
- Memory: 85MB
- Detection: 150-200ms
- **Status: Already optimized in defaults**

### Intel i5/i7 (2015+)

**Recommended Configuration:**
```json
{
  "daemon": {
    "polling_interval_ms": 500
  },
  "detection": {
    "method": "accessibility_api",
    "ocr_enabled": false
  }
}
```

**Results:**
- CPU: 0.5-1% idle
- Memory: 80MB
- Detection: 100-150ms
- **Note: Disable OCR for better performance**

### Older Intel (2012-2015)

**Aggressive Optimization:**
```json
{
  "daemon": {
    "polling_interval_ms": 1000
  },
  "detection": {
    "method": "accessibility_api",
    "ocr_enabled": false,
    "confidence_threshold": 0.90
  },
  "automation": {
    "click_delay_ms": 200
  },
  "database": {
    "max_retention_days": 30
  },
  "screenshots": {
    "capture_enabled": false
  }
}
```

**Results:**
- CPU: <1% idle
- Memory: 70MB
- Detection: 200-300ms
- **Trade-off: Slower but usable**

---

## Monitoring Performance

### Continuous Monitoring Script

```bash
#!/bin/bash
# monitor-performance.sh - Continuous performance monitoring

LOG_FILE="permissionpilot-perf-$(date +%Y%m%d).log"

while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Get CPU and Memory
  CPU=$(ps aux | grep PermissionPilot | grep -v grep | awk '{print $3}')
  MEM=$(ps aux | grep PermissionPilot | grep -v grep | awk '{print $6}')
  
  # Get recent event count
  EVENTS=$(sqlite3 ~/Library/Application\ Support/PermissionPilot/audit.db \
    "SELECT COUNT(*) FROM automation_events WHERE timestamp > datetime('now', '-1 minute');" 2>/dev/null || echo "0")
  
  # Log
  echo "$TIMESTAMP | CPU: ${CPU}% | Memory: ${MEM}MB | Recent Events: $EVENTS" >> "$LOG_FILE"
  
  # Display
  echo "$TIMESTAMP | CPU: ${CPU}% | Memory: ${MEM}MB | Recent Events: $EVENTS"
  
  sleep 10
done
```

### Alert on High Usage

```bash
#!/bin/bash
# alert-on-high-usage.sh - Alert if usage exceeds thresholds

CPU_THRESHOLD=5
MEM_THRESHOLD=200

while true; do
  CPU=$(ps aux | grep PermissionPilot | grep -v grep | awk '{print $3}' | cut -d. -f1)
  MEM=$(ps aux | grep PermissionPilot | grep -v grep | awk '{print $6}')
  
  if [ "$CPU" -gt "$CPU_THRESHOLD" ]; then
    echo "⚠️  HIGH CPU: ${CPU}%"
  fi
  
  if [ "$MEM" -gt "$MEM_THRESHOLD" ]; then
    echo "⚠️  HIGH MEMORY: ${MEM}MB"
  fi
  
  sleep 30
done
```

---

## Troubleshooting Performance Issues

### Symptom: High CPU (>5% idle)

**Diagnostic:**
```bash
# Check polling frequency
grep "polling_interval_ms" ~/Library/Application\ Support/PermissionPilot/config.json

# Check detection method
grep "method" ~/Library/Application\ Support/PermissionPilot/config.json
```

**Solutions:**
1. Increase polling_interval_ms: 500 → 1000
2. Disable OCR: ocr_enabled: false
3. Disable debug logging: debug_mode: false
4. Check for stuck processes: `top -o cpu`

### Symptom: High Memory (>150MB idle)

**Diagnostic:**
```bash
# Check database size
du -sh ~/Library/Application\ Support/PermissionPilot/audit.db

# Check screenshot directory
du -sh ~/Library/Application\ Support/PermissionPilot/screenshots/

# Check log files
du -sh ~/Library/Logs/PermissionPilot/
```

**Solutions:**
1. Clear old logs: Delete events >30 days
2. Disable screenshots: capture_enabled: false
3. Run VACUUM on database
4. Reduce retention: max_retention_days: 30

### Symptom: Slow Dialog Detection (>500ms)

**Diagnostic:**
```bash
# Check confidence threshold
grep "confidence_threshold" ~/Library/Application\ Support/PermissionPilot/config.json

# Check detection method
grep "method" ~/Library/Application\ Support/PermissionPilot/config.json

# Check OCR is working
log stream --predicate 'message contains "OCR"' --level debug
```

**Solutions:**
1. Lower confidence_threshold: 0.85 → 0.75
2. Use Accessibility API only: method: "accessibility_api"
3. Increase max_detection_retries
4. Check OCR isn't timing out

---

## Performance Tips Summary

| Issue | Solution | Impact |
|-------|----------|--------|
| High CPU | Increase polling interval | -50% CPU |
| High Memory | Reduce retention + disable screenshots | -40% Memory |
| Slow detection | Disable OCR | -2x faster (100ms) |
| Battery drain | Power Saver mode | -3x power usage |
| Conflicts | Increase debounce | Less CPU, less responsive |

---

**Last updated:** May 13, 2024  
**Version:** 1.0.0
