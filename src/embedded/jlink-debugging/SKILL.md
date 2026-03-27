---
name: jlink-debugging
description: Use when debugging ARM Cortex MCUs with J-Link, programming flash memory, or using J-Link GDB Server
---

# J-Link Debugging

## Overview

J-Link is SEGGER's debug probe for ARM Cortex-M microcontrollers. Provides fast flash programming and robust debugging via GDB.

**CRITICAL: All JLink command execution MUST be delegated to subAgents. Never run JLink commands directly in the main agent session.**

### Why SubAgents?

JLink operations (GDB server, RTT viewer, flash programming) are:
- **Long-running processes** that block the terminal
- **Stateful sessions** that need dedicated context
- **Resource-intensive** and should not pollute main agent context

Use `task(subagent_type="explore", run_in_background=true)` to spawn isolated JLink workers.

## SubAgent Delegation Pattern

```typescript
// Main agent: NEVER run JLink commands directly
// ❌ WRONG: Running in main context
JLinkGDBServer -device STM32F407VG -if SWD -speed 4000

// ✅ CORRECT: Delegate to subAgent
const taskId = task(
  category="quick",
  load_skills=["embedded/jlink-debugging"],
  run_in_background=true,
  description="Start JLink GDB server",
  prompt=`
    TASK: Start JLinkGDBServer for STM32F407VG
    COMMAND: JLinkGDBServer -device STM32F407VG -if SWD -speed 4000 -port 2331
    
    REQUIREMENTS:
    - Start the server and keep it running
    - Monitor for "Connected to target" message
    - Report any connection errors
    - Keep process alive until explicitly cancelled
  `
);

// Later: Check status or cancel
background_output(task_id=taskId);
background_cancel(taskId=taskId);  // When done
```

## SubAgent Task Templates

### Template 1: Flash Programming
```typescript
task(
  category="quick",
  load_skills=["embedded/jlink-debugging"],
  run_in_background=false,
  description="Flash firmware via JLink",
  prompt=`
    TASK: Program firmware to target device
    
    DEVICE: STM32F407VG (change as needed)
    FIRMWARE: build/firmware.hex (verify path exists)
    
    STEPS:
    1. Create temporary command file /tmp/flash.jlink:
       connect
       loadfile build/firmware.hex
       r
       g
       exit
    
    2. Execute: JLinkExe -device STM32F407VG -if SWD -speed 4000 -autoconnect 1 -CommanderScript /tmp/flash.jlink
    
    3. Capture and report:
       - Success confirmation
       - Any error messages
       - Programming time
    
    MUST NOT:
    - Leave JLinkExe in interactive mode
    - Assume default device (always specify)
  `
);
```

### Template 2: Start GDB Server (Background)
```typescript
const gdbServerTask = task(
  category="quick",
  load_skills=["embedded/jlink-debugging"],
  run_in_background=true,
  description="Start JLink GDB server",
  prompt=`
    TASK: Start JLink GDB Server for remote debugging
    
    DEVICE: STM32F407VG
    INTERFACE: SWD
    SPEED: 4000 kHz
    PORT: 2331
    
    COMMAND: JLinkGDBServer -device STM32F407VG -if SWD -speed 4000 -port 2331
    
    REQUIREMENTS:
    - Start server and wait for "Waiting for GDB connection" message
    - Keep process running (do not exit)
    - Log output to identify connection status
    - Report when ready for GDB connection
    
    MONITOR FOR:
    - "Connected to target" = hardware connected OK
    - "Failed to connect" = check wiring/power
    - "Cannot connect to J-Link" = driver/permission issue
  `
);

// Main agent can now proceed with other work
// GDB client connection is separate task
```

### Template 3: RTT Viewer (Background)
```typescript
const rttTask = task(
  category="quick",
  load_skills=["embedded/jlink-debugging"],
  run_in_background=true,
  description="Monitor RTT output",
  prompt=`
    TASK: Start J-Link RTT Viewer to capture firmware logs
    
    DEVICE: STM32F407VG
    COMMAND: JLinkRTTViewer -device STM32F407VG
    
    REQUIREMENTS:
    - Connect to target and start RTT
    - Capture all output lines
    - Buffer output (don't overwhelm with continuous prints)
    - Report every 10 seconds or when buffer has 50+ lines
    
    NOTE: Firmware must have SEGGER_RTT.c compiled in
  `
);
```

### Template 4: Interactive Debugging Session
```typescript
// Spawn both server and GDB client as separate subAgents
const serverTask = task(
  category="quick",
  load_skills=["embedded/jlink-debugging"],
  run_in_background=true,
  description="JLink GDB server",
  prompt=`Start JLinkGDBServer -device STM32F407VG -if SWD -speed 4000 -port 2331 and keep running`
);

// Wait a moment for server to start
await new Promise(r => setTimeout(r, 2000));

const gdbTask = task(
  category="quick",
  load_skills=["embedded/jlink-debugging", "embedded/embedded-gdb-debugging"],
  run_in_background=false,
  description="GDB debugging session",
  prompt=`
    TASK: Connect GDB to running JLink server and perform debugging
    
    GDB COMMANDS TO EXECUTE:
    1. target remote localhost:2331
    2. monitor reset
    3. load build/firmware.elf
    4. break main
    5. continue
    6. backtrace (when hit breakpoint)
    7. info registers
    
    REPORT:
    - Whether breakpoint was hit
    - Stack trace at breakpoint
    - Register values
    - Any errors encountered
  `
);
```

## Quick Reference

| Task | Command |
|------|---------|
| List connected probes | `JLinkExe -usb` |
| Interactive CLI | `JLinkExe -device STM32F407VG -if SWD -speed 4000` |
| Program firmware | `JLinkExe -commandfile flash.jlink` |
| Start GDB server | `JLinkGDBServer -device STM32F407VG -if SWD -speed 4000` |
| RTT viewer | `JLinkRTTViewer -device STM32F407VG` |

## Flash Programming

### Command File (flash.jlink)
```
connect
loadfile firmware.hex
r
g
exit
```

### One-liner flash
```bash
JLinkExe -device STM32F407VG -if SWD -speed 4000 -autoconnect 1 -CommanderScript <<EOF
loadfile build/firmware.hex
r
g
exit
EOF
```

## GDB Server Setup

### Terminal 1: Start server
```bash
JLinkGDBServer -device STM32F407VG -if SWD -speed 4000 -port 2331
```

### Terminal 2: Connect GDB
```bash
arm-none-eabi-gdb build/firmware.elf
(gdb) target remote localhost:2331
(gdb) monitor reset
(gdb) load
(gdb) continue
```

## Common GDB Commands

| Command | Description |
|---------|-------------|
| `monitor reset` | Hardware reset |
| `monitor halt` | Stop execution |
| `load` | Flash firmware |
| `info registers` | Show registers |
| `x/10x 0x20000000` | Examine memory |
| `set var variable=5` | Change variable |
| `break main` | Set breakpoint |

## RTT (Real-Time Transfer)

Zero-overhead printf replacement via debug interface:

```c
// In firmware
#include "SEGGER_RTT.h"

SEGGER_RTT_WriteString(0, "Hello from RTT\n");
SEGGER_RTT_printf(0, "Value: %d\n", value);
```

View output: `JLinkRTTViewer -device STM32F407VG`

## Complete Workflow Example

```typescript
// === PHASE 1: Flash Firmware ===
const flashResult = await task(
  category="quick",
  load_skills=["embedded/jlink-debugging"],
  run_in_background=false,
  description="Flash firmware",
  prompt=`Flash build/firmware.hex to STM32F407VG and report success/failure`
);

if (!flashResult.success) {
  // Handle flash failure in main agent context
  return;
}

// === PHASE 2: Start Debug Infrastructure ===
const serverTask = task(
  category="quick",
  load_skills=["embedded/jlink-debugging"],
  run_in_background=true,
  description="Start GDB server",
  prompt:`Start JLinkGDBServer -device STM32F407VG -if SWD -speed 4000 -port 2331`
);

const rttTask = task(
  category="quick",
  load_skills=["embedded/jlink-debugging"],
  run_in_background=true,
  description="Start RTT viewer",
  prompt:`Start JLinkRTTViewer -device STM32F407VG and capture logs`
);

// === PHASE 3: Debug Session (subAgent) ===
const debugResult = await task(
  category="quick",
  load_skills=["embedded/jlink-debugging", "embedded/embedded-gdb-debugging"],
  run_in_background=false,
  description="GDB debug session",
  prompt:`Connect GDB to localhost:2331, reset, load symbols, set breakpoint at main, continue for 10 seconds, then report findings`
);

// === PHASE 4: Cleanup ===
background_cancel(taskId=serverTask);
background_cancel(taskId=rttTask);

// Main agent context remains clean throughout
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Failed to connect" | Check SWDIO/SWCLK wiring, target power |
| "Cannot read memory" | Target may be in hard fault; use `monitor reset` |
| Slow flashing | Increase speed: `-speed 15000` |
| "Device not found" | Install J-Link Software & Documentation Pack |
| GDB "Remote replied" error | Restart JLinkGDBServer |
| SubAgent "command not found" | Ensure J-Link is installed and in PATH |

## VS Code Integration

`.vscode/launch.json`:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "J-Link Debug",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build/firmware.elf",
            "miDebuggerServerAddress": "localhost:2331",
            "miDebuggerPath": "arm-none-eabi-gdb",
            "debugServerPath": "JLinkGDBServer",
            "debugServerArgs": "-device STM32F407VG -if SWD -speed 4000",
            "serverStarted": "Connected to target"
        }
    ]
}
```

## Best Practices

### JLink Usage
1. **Always specify interface**: `-if SWD` (not auto-detect)
2. **Use device-specific names**: `STM32F407VG` not `Cortex-M4`
3. **Script repetitive operations**: Use `.jlink` command files
4. **Check J-Link version**: `JLinkExe -Version` for compatibility

### SubAgent Management
5. **Always delegate to subAgents**: Never run JLink commands in main session
6. **Use `run_in_background=true`** for long-running processes (GDB server, RTT viewer)
7. **Use `run_in_background=false`** for one-shot operations (flash programming)
8. **Cancel background tasks when done**: `background_cancel(taskId=...)`
9. **Store task IDs** for later status checks or cancellation

### Context Isolation Benefits
- ✅ Main agent remains responsive for user interaction
- ✅ Multiple JLink operations can run in parallel
- ✅ No terminal blocking from long-running GDB server
- ✅ Clean separation of concerns
