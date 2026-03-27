---
name: task-completion-hooks
description: Use when setting up automated actions to run after task completion, such as archiving, notifications, or cleanup
---

# Task Completion Hooks

## Overview

Hooks are automated actions triggered after task completion and verification. They ensure consistent post-task workflows without manual intervention.

**Common Hook Types:**
- **Archive Hook:** Document implementation details
- **Notification Hook:** Alert team members
- **Cleanup Hook:** Remove temporary files
- **Validation Hook:** Run final checks

## Hook Architecture

```
┌─────────────────────────────────────┐
│         Task Execution              │
│  (Implement, Test, Verify)          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│      Verification Gate              │
│  (All checks passed?)               │
└──────────────┬──────────────────────┘
               │ Yes
               ▼
┌─────────────────────────────────────┐
│      Hook Execution Pipeline        │
│  ┌─────────┐ ┌─────────┐ ┌────────┐ │
│  │ Archive │ │ Notify  │ │ Cleanup│ │
│  │  Hook   │ │  Hook   │ │  Hook  │ │
│  └─────────┘ └─────────┘ └────────┘ │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│         Task Complete               │
└─────────────────────────────────────┘
```

## Implementation Approaches

### Approach 1: SubAgent Delegation (Recommended)

Delegate hook execution to subAgents for isolation:

```typescript
// Main agent: Complete task, then trigger hooks

async function completeTask(taskContext) {
  // 1. Complete implementation
  await implementFeature();
  
  // 2. Verify
  const verified = await runVerification();
  if (!verified) return { status: 'failed' };
  
  // 3. Execute hooks via subAgents (non-blocking where possible)
  const hookTasks = [];
  
  // Archive hook
  hookTasks.push(task(
    category="writing",
    load_skills=["superpowers/task-archiving"],
    run_in_background=true,  // Non-blocking
    description="Archive completed task",
    prompt=`Create archive in docs/arch/ for: ${taskContext.summary}`
  ));
  
  // Notification hook (if needed)
  hookTasks.push(task(
    category="quick",
    run_in_background=true,
    description="Notify completion",
    prompt=`Send notification: Task ${taskContext.id} completed`
  ));
  
  // Wait for critical hooks
  await Promise.all(hookTasks);
  
  return { status: 'completed', hooks: hookTasks };
}
```

### Approach 2: Skill-Based Hook Registration

Register hooks within skill that auto-execute:

```typescript
// In your task execution skill
const TASK_HOOKS = {
  onComplete: [
    { skill: 'task-archiving', priority: 1 },
    { skill: 'verification-before-completion', priority: 2 }
  ]
};

// After task completion:
for (const hook of TASK_HOOKS.onComplete.sort((a,b) => a.priority - b.priority)) {
  await executeHook(hook, taskContext);
}
```

### Approach 3: Manual Hook Invocation

Explicitly call hook at end of task:

```typescript
// At end of task implementation
// === POST-TASK HOOKS ===

// Archive the work
await task(
  category="writing",
  load_skills=["superpowers/task-archiving"],
  run_in_background=false,
  description="Archive task",
  prompt=`
    Create archive entry for completed task:
    - Files: ${changedFiles.join(', ')}
    - Purpose: ${taskPurpose}
    - Decisions: ${keyDecisions}
  `
);
```

## Archive Hook Specifics

### When to Trigger

| Scenario | Trigger Archive? | Reasoning |
|----------|------------------|-----------|
| Bug fix (1 line) | Optional | Too small to justify overhead |
| Bug fix (complex) | Yes | Document root cause and fix |
| New feature | Yes | Capture design decisions |
| Refactor | Yes | Document motivation and approach |
| Config change | Maybe | Depends on impact |

### Archive Hook Template

```typescript
const archiveHook = {
  name: 'task-archive',
  execute: async (taskContext) => {
    const archivePath = `docs/arch/${formatDate(new Date())}-${taskContext.slug}.md`;
    
    return task(
      category="writing",
      load_skills=["superpowers/task-archiving"],
      run_in_background=false,
      description="Create task archive",
      prompt=`
        TASK: Create comprehensive archive entry
        
        ARCHIVE_PATH: ${archivePath}
        
        TASK_CONTEXT:
        ${JSON.stringify(taskContext, null, 2)}
        
        REQUIRED SECTIONS:
        1. Summary - what was done
        2. Problem Statement - why it was needed
        3. Solution - how it was solved
        4. Decisions - key choices and trade-offs
        5. Lessons - what worked, what didn't
        6. Applicability - when to use this approach
        
        QUALITY CHECKLIST:
        - [ ] Specific enough to be actionable
        - [ ] Includes failed approaches (not just final solution)
        - [ ] Links to code, PRs, tickets
        - [ ] Written for future developers
      `
    );
  }
};
```

## Hook Ordering

```
Priority 1: Validation hooks (must pass)
Priority 2: Archive hooks (document while fresh)
Priority 3: Notification hooks (inform stakeholders)
Priority 4: Cleanup hooks (remove temp files)
```

## Error Handling

### Hook Failure Modes

| Failure | Handling | Example |
|---------|----------|---------|
| Critical hook fails | Fail task | Validation hook fails |
| Important hook fails | Warn, continue | Archive write fails |
| Optional hook fails | Silent ignore | Notification fails |

### Implementation

```typescript
async function executeHook(hook, context) {
  try {
    return await hook.execute(context);
  } catch (error) {
    if (hook.critical) {
      throw new TaskError(`Critical hook failed: ${hook.name}`, error);
    }
    console.warn(`Hook ${hook.name} failed (non-critical):`, error);
    return { status: 'failed', error };
  }
}
```

## Best Practices

### Hook Design
1. **Idempotency:** Running hook twice should not cause issues
2. **Isolation:** Use subAgents to avoid polluting main context
3. **Async where possible:** Don't block on non-critical hooks
4. **Clear failure modes:** Distinguish critical vs optional hooks

### Archive Hook Specific
1. **Extract context while fresh:** Don't rely on memory later
2. **Include decisions, not just code:** Document the "why"
3. **Link everything:** Code, PRs, tickets, related archives
4. **Make it searchable:** Use keywords, tags, clear titles

### Maintenance
1. **Review hooks periodically:** Are they still valuable?
2. **Measure hook overhead:** Don't let hooks slow down development
3. **Update templates:** Keep archive templates current
