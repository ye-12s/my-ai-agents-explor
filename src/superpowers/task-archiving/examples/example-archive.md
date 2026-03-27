# J-Link SubAgent Integration

**Archive Date:** 2024-03-27 23:15  
**Related Tickets:** N/A (Skill Enhancement)  
**Author:** @assistant  
**Status:** ✅ Completed

---

## Summary

Enhanced the `jlink-debugging` skill to enforce SubAgent delegation for all JLink operations. This prevents main agent context pollution from long-running debug sessions and enables parallel debugging workflows.

## Problem Statement

JLink operations (GDB server, RTT viewer, flash programming) caused several issues when run in main agent context:

1. **Blocking:** `JLinkGDBServer` and serial monitoring commands block indefinitely
2. **Context pollution:** GDB state, register dumps, and memory contents cluttered main agent context
3. **No parallelism:** Only one debug session possible at a time
4. **Resource leaks:** Forgotten background processes after task completion

We needed a pattern that keeps the main agent responsive while supporting complex debugging workflows.

## Solution Overview

Refactored `jlink-debugging` and related embedded skills to use SubAgent delegation pattern:

- Long-running processes → `run_in_background=true`
- One-shot operations → `run_in_background=false`
- Structured prompts with specific success criteria
- Automatic resource cleanup via `background_cancel()`

### Files Changed

| File | Change Type | Purpose |
|------|-------------|---------|
| `~/.agents/skills/embedded/jlink-debugging/SKILL.md` | Modify | Added SubAgent delegation patterns |
| `~/.agents/skills/embedded/embedded-serial-debugging/SKILL.md` | Modify | Added SubAgent patterns for serial monitoring |
| `~/.agents/skills/embedded/embedded-gdb-debugging/SKILL.md` | Modify | Added SubAgent patterns for GDB sessions |

### Key Implementation Details

```typescript
// Pattern: Delegate to subAgent with specific goals
const gdbServerTask = task(
  category="quick",
  load_skills=["embedded/jlink-debugging"],
  run_in_background=true,  // Non-blocking
  description="Start JLink GDB server",
  prompt:`
    TASK: Start JLink GDB Server
    COMMAND: JLinkGDBServer -device STM32F407VG -if SWD -speed 4000
    
    REQUIREMENTS:
    - Wait for "Waiting for GDB connection" message
    - Report any connection errors
    - Keep running until cancelled
  `
);

// Main agent continues immediately
// Later: Clean up
background_cancel(taskId=gdbServerTask);
```

## Technical Decisions

### Decision 1: Background vs Foreground SubAgents
**Chosen:** Use `run_in_background=true` for servers/monitors, `false` for one-shot tasks  
**Alternatives Considered:** Always background, always foreground  
**Rationale:** Servers need to run indefinitely; one-shot tasks should report results before continuing  
**Trade-offs:** Requires careful task ID management for cleanup

### Decision 2: Skill Self-Documentation
**Chosen:** Include SubAgent patterns directly in skill documentation  
**Alternatives Considered:** Separate "hook" skill, external templates  
**Rationale:** Patterns are discoverable where needed; templates stay synchronized with skill updates  
**Trade-offs:** Skill documents become longer

### Decision 3: Structured Prompts
**Chosen:** Explicit prompt sections (TASK, COMMAND, REQUIREMENTS)  
**Alternatives Considered:** Minimal prompts, relying on skill loading  
**Rationale:** Clearer success criteria, more consistent subAgent behavior  
**Trade-offs:** More verbose, but worth it for reliability

## Lessons Learned

### What Worked Well
- **SubAgent isolation:** Main agent stays responsive during long debug sessions
- **Parallel debugging:** Can run GDB server + RTT viewer + serial monitor simultaneously
- **Clean context:** No GDB register dumps polluting main agent context
- **Structured output:** SubAgents return analyzed results, not raw terminal output

### What Didn't Work
- Initially tried to use `subagent_type="explore"` but `category="quick"` is more appropriate for command execution
- First iteration lacked explicit cleanup instructions; subAgents sometimes left processes running

### Surprises
- SubAgents with `run_in_background=true` can be cancelled cleanly with `background_cancel()`
- The pattern applies beyond JLink - useful for any long-running external tool (Docker, emulators, etc.)

## Applicability

### When to Use This Approach
✅ Use when:
- Running long-lived external processes (servers, monitors, viewers)
- Need parallel execution of multiple tools
- Want to keep main agent context clean
- External tool output needs parsing/analysis before use

### When NOT to Use
❌ Avoid when:
- Simple one-off commands that return immediately
- Need interactive user input during command execution
- External tool must share filesystem state with main agent (use worktrees instead)

### Related Archives
- None yet - this is the first SubAgent pattern archive

## References

- Skill location: `~/.agents/skills/embedded/jlink-debugging/`
- Related skills: `embedded-serial-debugging`, `embedded-gdb-debugging`
- Pattern inspiration: `superpowers/dispatching-parallel-agents`
