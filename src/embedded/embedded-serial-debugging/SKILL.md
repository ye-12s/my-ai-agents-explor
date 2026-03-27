---
name: embedded-serial-debugging
description: Use when debugging embedded systems via UART/serial port, configuring baud rates, or troubleshooting serial communication issues
---

# Embedded Serial Debugging

## Overview

Serial/UART is the primary debugging interface for embedded systems. Master the complete workflow from physical connection to software analysis.

**CRITICAL: All serial monitoring MUST be delegated to subAgents. Never run blocking serial commands (screen, minicom, cat /dev/ttyUSB*) directly in the main agent session.**

### Why SubAgents?

Serial monitoring operations are:
- **Blocking/long-running** - `cat /dev/ttyUSB0` runs indefinitely
- **Resource-intensive** - Continuous I/O that pollutes main agent context
- **Parallelizable** - Multiple ports can be monitored simultaneously

Use `task(category="quick", run_in_background=true)` to spawn isolated serial monitors.

## SubAgent Delegation Pattern

```typescript
// Main agent: NEVER run blocking serial commands directly
// ❌ WRONG: Blocks main context indefinitely
cat /dev/ttyUSB0

// ✅ CORRECT: Delegate to subAgent
const serialTask = task(
  category="quick",
  load_skills=["embedded/embedded-serial-debugging"],
  run_in_background=true,
  description="Monitor serial port",
  prompt=`
    TASK: Monitor /dev/ttyUSB0 at 115200 baud and capture logs
    
    COMMAND OPTIONS (choose one):
    - Python: python3 -c "import serial; s=serial.Serial('/dev/ttyUSB0',115200); [print(l.decode().strip()) for l in s]"
    - Miniterm: python3 -m serial.tools.miniterm /dev/ttyUSB0 115200
    
    REQUIREMENTS:
    - Add timestamps to each line: [HH:MM:SS] message
    - Buffer 50 lines before reporting to reduce noise
    - Detect common patterns and report:
      * "ERROR" / "FAULT" / "ASSERT" → Report immediately
      * Boot messages → Report first 20 lines
    - Keep running until cancelled
    
    INITIAL SETUP:
    - Verify port exists: ls -la /dev/ttyUSB0
    - Check permissions: groups (should include 'dialout')
    - If permission denied, report but don't fail
  `
);

// Later: Get captured logs
background_output(task_id=serialTask);

// When done: Cancel
background_cancel(taskId=serialTask);
```

## SubAgent Task Templates

### Template 1: Serial Logger with File Output
```typescript
const loggerTask = task(
  category="quick",
  load_skills=["embedded/embedded-serial-debugging"],
  run_in_background=true,
  description="Serial logger to file",
  prompt=`
    TASK: Log serial output to timestamped file
    
    PORT: /dev/ttyUSB0
    BAUD: 115200
    OUTPUT: /tmp/serial_$(date +%Y%m%d_%H%M%S).log
    
    APPROACH:
    1. Use Python script for reliable logging with timestamps
    2. Write to file AND output periodic summaries
    3. Report:
       - File path being written
       - Line count every 30 seconds
       - Any error/fault keywords detected
    
    PYTHON SCRIPT TEMPLATE:
    import serial
    import datetime
    import sys
    
    ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=1)
    with open('/tmp/serial.log', 'a') as f:
        while True:
            line = ser.readline()
            if line:
                ts = datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]
                msg = f"[{ts}] {line.decode('utf-8', errors='ignore').strip()}"
                f.write(msg + '\\n')
                f.flush()
  `
);
```

### Template 2: Baud Rate Detection
```typescript
const baudTask = task(
  category="quick",
  load_skills=["embedded/embedded-serial-debugging"],
  run_in_background=false,
  description="Detect serial baud rate",
  prompt=`
    TASK: Automatically detect correct baud rate for /dev/ttyUSB0
    
    APPROACH:
    1. Test common baud rates in descending order: 115200, 57600, 38400, 19200, 9600
    2. For each rate:
       - Open port with 2-second timeout
       - Try to read lines for 3 seconds
       - Check if output is readable ASCII (not garbled)
    3. Report first rate that produces clean output
    
    SUCCESS CRITERIA:
    - Output contains mostly printable ASCII (32-126)
    - No more than 10% non-ASCII characters
    - Detects consistent line endings (\\n or \\r\\n)
    
    MUST REPORT:
    - Detected baud rate (if found)
    - Sample of readable output (first 5 lines)
    - Or: "No readable output at any standard baud rate"
  `
);
```

### Template 3: Pattern Monitor (Error Detection)
```typescript
const monitorTask = task(
  category="quick",
  load_skills=["embedded/embedded-serial-debugging"],
  run_in_background=true,
  description="Monitor for errors/patterns",
  prompt=`
    TASK: Monitor serial port and alert on specific patterns
    
    PORT: /dev/ttyUSB0
    BAUD: 115200
    
    CRITICAL PATTERNS (report immediately):
    - "ERROR", "FAULT", "ASSERT", "PANIC", "CRASH"
    - "HardFault", "BusFault", "MemManage"
    - Stack traces (lines starting with "  at " or "0x")
    
    BOOT PATTERNS (report first occurrence):
    - "Booting", "Starting", "Initializing"
    - Version strings (e.g., "Version:", "v1.2.3")
    
    OUTPUT:
    - Immediate alerts for critical patterns with context (5 lines before/after)
    - Summary every 60 seconds: lines read, patterns found
    - Save full log to /tmp/serial_monitor.log
  `
);
```

### Template 4: Multi-Port Monitoring
```typescript
// Monitor multiple serial ports in parallel
const tasks = [];

for (const port of ['/dev/ttyUSB0', '/dev/ttyUSB1']) {
  const taskId = task(
    category="quick",
    load_skills=["embedded/embedded-serial-debugging"],
    run_in_background=true,
    description=`Monitor ${port}`,
    prompt=`Monitor ${port} at 115200 baud, prefix output with [${port}], buffer and report every 20 seconds`
  );
  tasks.push(taskId);
}

// Later: Collect results from all ports
for (const taskId of tasks) {
  background_output(task_id=taskId);
}

// Cleanup
for (const taskId of tasks) {
  background_cancel(taskId=taskId);
}
```

## Quick Reference

| Task | Command/Tool |
|------|--------------|
| List serial ports | `ls /dev/ttyUSB*` (Linux) / `ls /dev/tty.*` (macOS) |
| Monitor with screen | `screen /dev/ttyUSB0 115200` |
| Monitor with minicom | `minicom -D /dev/ttyUSB0 -b 115200` |
| Python serial read | `python3 -m serial.tools.miniterm /dev/ttyUSB0 115200` |
| Log to file | `cat /dev/ttyUSB0 > serial.log` |

## Common Configurations

### Standard Settings
- **Baud rate**: 115200 (most common), 9600 (legacy)
- **Data bits**: 8
- **Parity**: None
- **Stop bits**: 1
- **Flow control**: None

### Finding Correct Baud Rate
```bash
# Try common rates in order
for rate in 115200 57600 38400 19200 9600; do
    echo "Testing $rate..."
    timeout 2 minicom -D /dev/ttyUSB0 -b $rate || true
done
```

## Connection Checklist

- [ ] TX→RX, RX→TX (cross-over, NOT straight-through)
- [ ] Common ground connected
- [ ] Correct voltage level (3.3V vs 5V)
- [ ] Baud rate matches target device
- [ ] USB adapter drivers installed

## Python Script Template

```python
import serial
import serial.tools.list_ports

# List available ports
ports = serial.tools.list_ports.comports()
for p in ports:
    print(f"{p.device}: {p.description}")

# Open connection
ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=1)

# Read line by line
while True:
    line = ser.readline().decode('utf-8', errors='ignore').strip()
    if line:
        print(f"[{time.strftime('%H:%M:%S')}] {line}")

ser.close()
```

## Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Garbled output | Wrong baud rate | Match device configuration |
| No output | TX/RX swapped | Reverse connections |
| Random noise | Missing ground | Connect GND between devices |
| Permission denied | Udev rules | Add user to `dialout` group |
| Broken pipes | USB disconnect | Check cable/connection |

## Best Practices

### Serial Monitoring
1. **Always timestamp logs** - Include [HH:MM:SS] prefix
2. **Use device ID paths** - `/dev/serial/by-id/usb-*` for stable naming across reconnects
3. **Check permissions** - User must be in `dialout` group
4. **Verify wiring** - TX→RX, RX→TX (cross-over), common GND

### SubAgent Management
5. **Always delegate to subAgents** - Never run blocking serial commands in main session
6. **Use `run_in_background=true`** for continuous monitoring
7. **Use `run_in_background=false`** for one-shot operations (baud detection, port listing)
8. **Buffer output** - Don't report every line; aggregate and report periodically
9. **Cancel tasks when done** - `background_cancel(taskId=...)` to release resources
10. **Handle permissions gracefully** - Report "dialout group needed" rather than crashing

### Context Isolation Benefits
- ✅ Main agent stays responsive for user interaction
- ✅ Multiple serial ports can be monitored in parallel
- ✅ No blocking I/O in main context
- ✅ Clean log aggregation from multiple sources
- ✅ Automatic resource cleanup on cancellation
