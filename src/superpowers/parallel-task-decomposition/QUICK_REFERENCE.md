# Parallel Task Decomposition - Quick Reference

## Decision Flowchart

```
Start
  │
  ▼
┌─────────────────────────┐
│ Is task complex enough  │ No ──► Don't decompose
│ to benefit from         │        (overhead > benefit)
│ parallel execution?     │
└──────────┬──────────────┘
           │ Yes
           ▼
┌─────────────────────────┐
│ Can it be split into    │ No ──► Don't decompose
│ independent subtasks?   │        (too coupled)
│ (no shared mutable      │
│ state)                  │
└──────────┬──────────────┘
           │ Yes
           ▼
┌─────────────────────────┐
│ Identify dependencies   │
│ between subtasks        │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Draw dependency graph   │
│ (DAG check)             │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Group into phases       │
│ (topological sort)      │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Dispatch Phase 1        │
│ (all parallel)          │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Wait for completion     │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Validate results        │
└──────────┬──────────────┘
           │
           ▼
     ┌─────┴─────┐
     │ More      │
     │ phases?   │
     └─────┬─────┘
      Yes  │   │ No
           │   ▼
           │ ┌─────────────────┐
           │ │ Integrate all   │
           │ │ results         │
           │ └────────┬────────┘
           │          │
           │          ▼
           │    ┌───────────┐
           └────┤ Next      │
                │ phase     │
                └─────┬─────┘
                      │
                      ▼
               ┌──────────────┐
               │ Final        │
               │ verification │
               └──────┬───────┘
                      │
                      ▼
                  Complete
```

## Pre-Decomposition Checklist

- [ ] **Task complexity** > 15 minutes of work
- [ ] **No shared mutable state** between subtasks
- [ ] **Clear boundaries** - each subtask has single responsibility
- [ ] **Independent verification** - each subtask can be tested alone
- [ ] **Dependencies form DAG** - no circular dependencies
- [ ] **Worth the overhead** - coordination cost < parallel benefit

## Anti-Patterns Quick Check

| ❌ Don't Do This | ✅ Do This Instead |
|------------------|-------------------|
| Tasks modify same file | Each task owns separate files |
| Task B reads Task A's output | Pass A's result explicitly to B's prompt |
| Implicit global state | Explicit context in prompts |
| Real-time coordination | Fire-and-forget, integrate later |
| Fine-grained tasks (< 2 min) | Batch small tasks together |

## Command Reference

### Basic Parallel Dispatch

```typescript
// Dispatch multiple tasks in parallel
const tasks = ['a', 'b', 'c'].map(id =>
  task({
    category: "quick",
    run_in_background: true,
    description: `Task ${id}`,
    prompt: `Implement ${id}`
  })
);

// Wait for all
const results = await Promise.all(
  tasks.map(t => background_output(t))
);
```

### Phased Execution

```typescript
// Phase 1: Foundation
const phase1 = await Promise.all([
  task({ run_in_background: true, prompt: "Task A" }),
  task({ run_in_background: true, prompt: "Task B" })
].map(t => background_output(t)));

// Phase 2: Build on Phase 1
const phase2 = await Promise.all([
  task({ 
    run_in_background: true, 
    prompt: `Task C (uses: ${JSON.stringify(phase1)})` 
  })
].map(t => background_output(t)));
```

### Dynamic Scheduling

```typescript
const completed = new Set();
const running = new Set();
const pending = new Set(['a', 'b', 'c', 'd']);

function scheduleReady() {
  const ready = [...pending].filter(id => 
    deps[id].every(d => completed.has(d))
  );
  
  ready.forEach(id => {
    pending.delete(id);
    running.add(id);
    
    task({
      run_in_background: true,
      prompt: buildPrompt(id)
    }).then(result => {
      running.delete(id);
      completed.add(id);
      scheduleReady(); // Trigger next wave
    });
  });
}

scheduleReady();
```

## Common Dependency Patterns

### Star Pattern (Parallel)
```
    ┌───┐
    │ A │  (foundation)
    └─┬─┘
      │
  ┌───┼───┐
  ▼   ▼   ▼
┌──┐┌──┐┌──┐
│B ││C ││D │  (parallel, independent)
└──┘└──┘└──┘
```

### Chain Pattern (Sequential)
```
┌───┐    ┌───┐    ┌───┐    ┌───┐
│ A │───►│ B │───►│ C │───►│ D │
└───┘    └───┘    └───┘    └───┘
```
**Optimization:** Consider if chain can be broken - does B really need ALL of A?

### Diamond Pattern (Fork-Join)
```
    ┌───┐
    │ A │
    └─┬─┘
      │
  ┌───┴───┐
  ▼       ▼
┌───┐   ┌───┐
│ B │   │ C │  (parallel)
└───┘   └───┘
  │       │
  └───┬───┘
      ▼
    ┌───┐
    │ D │  (integration)
    └───┘
```

## Troubleshooting

### Issue: Tasks Keep Conflicting

**Symptoms:** Multiple subtasks modifying same files

**Solutions:**
1. Redefine boundaries - give each task exclusive file ownership
2. Use worktrees for complete isolation
3. Add integration phase that handles conflicts

### Issue: Circular Dependencies

**Symptoms:** Cannot determine execution order

**Solutions:**
1. Refactor to break the cycle
2. Extract common dependency into separate Phase 0 task
3. Merge circularly-dependent tasks into single subtask

### Issue: Overhead Exceeds Benefit

**Symptoms:** Parallel execution slower than sequential

**Solutions:**
1. Increase task granularity (batch small tasks)
2. Reduce number of phases
3. Skip decomposition for simple tasks

### Issue: Results Don't Integrate

**Symptoms:** Subtask outputs incompatible

**Prevention:**
1. Define explicit output contracts upfront
2. Create interface definitions in Phase 0
3. Validate outputs before accepting

## Estimation Guide

| Task Complexity | Subtasks | Phases | Est. Speedup |
|----------------|----------|--------|--------------|
| 4 components, independent | 4 | 1 | 4x |
| 4 components, 2 depend on 2 | 4 | 2 | 2x |
| 8 endpoints, shared DB | 8 | 2 | 4x |
| 3-layer refactor | 3 | 3 | 1.5x |

## Quick Start Template

```typescript
// 1. Define tasks
const tasks = [
  { id: 'a', deps: [], scope: 'src/a/' },
  { id: 'b', deps: [], scope: 'src/b/' },
  { id: 'c', deps: ['a', 'b'], scope: 'src/c/' }
];

// 2. Compute phases
const phases = computePhases(tasks);

// 3. Execute phases
for (const phase of phases) {
  const taskIds = phase.map(t =>
    task({
      category: "quick",
      run_in_background: true,
      prompt: buildPrompt(t)
    })
  );
  
  await Promise.all(taskIds.map(id => background_output(id)));
}

// 4. Done!
```
