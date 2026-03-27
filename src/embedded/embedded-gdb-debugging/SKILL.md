---
name: embedded-gdb-debugging
description: Use when debugging embedded firmware with GDB, examining hard faults, analyzing stack traces, or debugging without source code
---

# Embedded GDB Debugging

## Overview

GDB debugging for ARM Cortex-M microcontrollers. Focus on embedded-specific techniques: remote targets, memory examination, and fault analysis.

**CRITICAL: Interactive GDB sessions MUST run in subAgents. Never start an interactive GDB session in the main agent context.**

### Why SubAgents?

GDB debugging sessions are:
- **Interactive and stateful** - require continuous back-and-forth with debugger
- **Long-running** - may pause at breakpoints for extended periods
- **Complex context** - register states, stack frames, memory contents pollute main agent

Use `task(category="quick", run_in_background=false)` for targeted debugging tasks with specific goals.

## SubAgent Delegation Pattern

```typescript
// Main agent: NEVER run interactive GDB in main context
// ❌ WRONG: Blocks indefinitely at breakpoint
arm-none-eabi-gdb build/firmware.elf

// ✅ CORRECT: Delegate specific debugging task to subAgent
const debugResult = task(
  category="quick",
  load_skills=["embedded/embedded-gdb-debugging", "embedded/jlink-debugging"],
  run_in_background=false,
  description="Analyze hard fault",
  prompt=`
    TASK: Analyze hard fault using GDB
    
    TARGET: localhost:2331 (JLink GDB server already running)
    FIRMWARE: build/firmware.elf
    
    GDB COMMAND SEQUENCE:
    1. target remote localhost:2331
    2. monitor halt
    3. info registers (capture all)
    4. x/16x $sp (stack contents)
    5. x/i $pc (faulting instruction)
    6. p/x *0xE000ED28 (CFSR)
    7. p/x *0xE000ED2C (HFSR)
    8. info line *$pc (source location)
    9. bt (backtrace if available)
    
    REPORT:
    - Fault type (from CFSR/HFSR bits)
    - Faulting instruction address and source line
    - Register values at fault
    - Stack trace if available
    - Root cause analysis (e.g., "Null pointer dereference at address 0x0")
  `
);

// Main agent receives structured report, not raw GDB output
```

## SubAgent Task Templates

### Template 1: Hard Fault Analysis
```typescript
task(
  category="quick",
  load_skills=["embedded/embedded-gdb-debugging"],
  run_in_background=false,
  description="Hard fault diagnosis",
  prompt=`
    TASK: Diagnose hard fault from register dump
    
    REGISTERS PROVIDED:
    - PC = 0x08001234
    - LR = 0x08000456
    - SP = 0x20001000
    - PSR = 0x21000000
    
    STEPS:
    1. Connect to target: target remote localhost:2331
    2. Load symbols: file build/firmware.elf
    3. Find fault location: info line *0x08001234
    4. Get function: info symbol 0x08001234
    5. Check caller: info symbol 0x08000456
    6. Examine stack: x/16x 0x20001000
    7. Read fault status: p/x *0xE000ED28 (CFSR)
    
    OUTPUT FORMAT:
    Fault Location: [function:line]
    Fault Type: [BUSFAULT/MEMFAULT/USEFAULT from CFSR]
    Call Stack: [caller -> fault site]
    Likely Cause: [analysis]
  `
);
```

### Template 2: Memory Dump Analysis
```typescript
task(
  category="quick",
  load_skills=["embedded/embedded-gdb-debugging"],
  run_in_background=false,
  description="Dump and analyze memory",
  prompt=`
    TASK: Dump memory region and analyze contents
    
    ADDRESS: 0x20000000 (RAM start)
    SIZE: 256 bytes
    
    GDB COMMANDS:
    1. target remote localhost:2331
    2. x/64wx 0x20000000 (hex dump)
    3. x/64gx 0x20000000 (if 64-bit values)
    4. x/256bx 0x20000000 (byte view for strings)
    
    ANALYSIS:
    - Look for ASCII strings
    - Identify pointer patterns (0x08xxxxxx = Flash, 0x20xxxxxx = RAM)
    - Check for stack canary patterns
    - Report any obvious corruption markers (0xDEADBEEF, etc.)
  `
);
```

### Template 3: Post-Mortem from Crash Log
```typescript
task(
  category="quick",
  load_skills=["embedded/embedded-gdb-debugging"],
  run_in_background=false,
  description="Analyze crash from log",
  prompt=`
    TASK: Analyze crash from provided register dump
    
    CRASH LOG:
    ---
    HardFault_Handler
    R0 = 00000000
    R1 = 20001000
    R2 = 000000FF
    R3 = 08001234
    R12= 00000000
    LR = 08000456
    PC = 08000789
    PSR= 21000000
    ---
    
    ANALYSIS STEPS:
    1. file build/firmware.elf
    2. info line *0x08000789 (fault PC)
    3. info symbol 0x08000789 (fault function)
    4. info symbol 0x08000456 (caller)
    5. Disassemble fault site: disassemble 0x08000780,0x080007A0
    
    ROOT CAUSE ANALYSIS:
    - Identify instruction that faulted
    - Check for null pointer (R0=0 suggests null deref)
    - Verify alignment requirements
    - Report likely cause and fix suggestion
  `
);
```

### Template 4: Automated Debug Session
```typescript
// Run automated debugging sequence
const debugTask = task(
  category="quick",
  load_skills=["embedded/embedded-gdb-debugging", "embedded/jlink-debugging"],
  run_in_background=false,
  description="Automated debug session",
  prompt=`
    TASK: Run automated GDB debug session with specific goals
    
    PREREQUISITES:
    - JLink GDB server running on localhost:2331
    - Firmware ELF at build/firmware.elf
    
    DEBUG SEQUENCE:
    1. target remote localhost:2331
    2. monitor reset
    3. load build/firmware.elf
    4. break main
    5. continue (wait for breakpoint)
    6. backtrace
    7. info locals
    8. break Error_Handler
    9. continue (run for 10 seconds or until Error_Handler)
    10. If stopped at Error_Handler: bt full, info registers
    
    REPORT:
    - Did main breakpoint hit?
    - Did Error_Handler trigger?
    - Full stack trace if error occurred
    - Local variables at error point
    - Total execution time
  `
);
```

## Quick Reference

| Task | Command |
|------|---------|
| Connect to target | `target remote localhost:2331` |
| Load firmware | `load` |
| Reset | `monitor reset` |
| Hard fault analysis | `info registers` → `x/16x $sp` |
| Set hardware breakpoint | `hbreak main` |
| Continue | `continue` or `c` |
| Step instruction | `stepi` or `si` |
| Examine memory | `x/10wx 0x20000000` |
| Disassemble | `disassemble /m function_name` |

## Startup Sequence

```bash
arm-none-eabi-gdb build/firmware.elf

(gdb) target remote localhost:2331      # Connect to J-Link/OpenOCD
(gdb) monitor reset                      # Reset target
(gdb) load                               # Flash firmware
(gdb) break main                         # Set breakpoint
(gdb) continue                           # Run
```

## Hard Fault Debugging

### 1. Capture fault state
```
(gdb) info registers
(gdb) x/16x $sp                         # Stack contents
(gdb) x/i $pc                           # Faulting instruction
(gdb) p/x *0xE000ED28                   # CFSR (Configurable Fault Status)
(gdb) p/x *0xE000ED2C                   # HFSR (Hard Fault Status)
(gdb) p/x *0xE000ED30                   # DFSR (Debug Fault Status)
(gdb) p/x *0xE000ED34                   # MMFAR (MemManage Fault Address)
(gdb) p/x *0xE000ED38                   # BFAR (Bus Fault Address)
```

### 2. Parse CFSR bits
```
Bit 25: DIVBYZERO - Divide by zero
Bit 24: UNALIGNED - Unaligned access
Bit 18: INVSTATE  - Invalid EPSR state
Bit 17: INVPC     - Invalid PC load
Bit 16: NOCP      - No coprocessor
Bit  7: MMARVALID - MMFAR is valid
Bit 15: BFARVALID - BFAR is valid
```

### 3. Find fault location
```
(gdb) info line *$pc                     # Source line from PC
(gdb) info symbol $pc                    # Function name
(gdb) bt                                 # Backtrace if available
```

## Memory Examination

### Stack analysis
```
(gdb) info registers sp lr pc
(gdb) x/32x $sp-32                      # Stack contents
(gdb) frame 1                           # Go up one frame
(gdb) info locals                       # Local variables
```

### Peripheral registers
```
(gdb) set {unsigned int}0x40021018 = 0x1  # Write to RCC
(gdb) x/wx 0x40021018                    # Read register
(gdb) x/10wx 0x40020000                  # Dump GPIOA registers
```

## Breakpoint Strategies

### Hardware vs Software
```
(gdb) break main                         # Software (FLASH patch)
(gdb) hbreak main                        # Hardware (limited, fast)
(gdb) break *0x08001234                  # Address breakpoint
(gdb) break main if i==10                # Conditional
```

### Temporary breakpoints
```
(gdb) tbreak setup                       # Break once, then remove
(gdb) continue
```

## Watchpoints (Data Breakpoints)

```
(gdb) watch global_var                   # Break on write
(gdb) rwatch buffer                      # Break on read
(gdb) awatch status                      # Break on read/write
```

## Post-Mortem Debugging

### Using coredump (if supported)
```bash
# Generate coredump from running target
gdb-multiarch -ex "target remote :2331" \
              -ex "gcore firmware.core" \
              -ex "detach" \
              -ex "quit"

# Analyze later
gdb firmware.elf firmware.core
```

### From crash log
Given register dump from fault handler:
```
R0 = 00000000
R1 = 20001000
R2 = 000000FF
R3 = 08001234
R12= 00000000
LR = 08000456
PC = 08000789
PSR= 21000000
```

Find location:
```
(gdb) info line *0x08000789
(gdb) list *0x08000789
(gdb) info symbol 0x08000456            # Who called us
```

## GDB Script Automation

`.gdbinit` for embedded:
```
set history save on
set history filename ~/.gdb_history
set history size 1000

# Pretty printing
set print pretty on
set print array on

# Don't stop on SIGUSR1/SIGUSR2
handle SIGUSR1 nostop noprint
handle SIGUSR2 nostop noprint

define reset
    monitor reset
    flushregs
end

define reload
    monitor reset halt
    load
    monitor reset
end
```

## Common Issues

| Issue | Command |
|-------|---------|
| "Cannot access memory" | `set mem inaccessible-by-default off` |
| Wrong architecture | `set architecture arm` |
| Optimized-out variables | Compile with `-O0` or use `volatile` |
| Breakpoint won't set | Use hardware breakpoint: `hbreak` |
| "Remote replied" error | Restart GDB server |

## GDB Dashboard (Optional)

Install [gdb-dashboard](https://github.com/cyrus-and/gdb-dashboard) for enhanced UI:
```bash
curl -o ~/.gdbinit-dashboard https://raw.githubusercontent.com/cyrus-and/gdb-dashboard/master/.gdbinit
# Add to ~/.gdbinit: source ~/.gdbinit-dashboard
```

## Best Practices

### GDB Usage
1. **Always use `monitor reset` before `load`** - Ensures clean state
2. **Prefer `hbreak` over `break` on flash** - Hardware breakpoints don't require FLASH patch
3. **Check CFSR/HFSR first on hard fault** - Fault status registers tell you what happened
4. **Use `info line *$pc` to find source location** - Quickly map PC to code

### SubAgent Management
5. **Always delegate GDB sessions to subAgents** - Never run interactive GDB in main context
6. **Use `run_in_background=false`** for targeted debugging with specific goals
7. **Define clear success criteria** in subAgent prompt (e.g., "find fault location", "capture stack trace")
8. **Request structured output** from subAgent, not raw GDB output
9. **Chain subAgents** - GDB subAgent can follow JLink server subAgent

### Context Isolation Benefits
- ✅ Main agent stays focused on high-level debugging strategy
- ✅ Complex GDB state doesn't pollute main context
- ✅ Parallel debugging possible (multiple targets)
- ✅ Automatic cleanup after debugging session
- ✅ Structured reports instead of raw terminal output
