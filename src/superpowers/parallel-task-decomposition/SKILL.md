---
name: parallel-task-decomposition
description: Use when facing complex multi-step tasks that can be broken into independent subtasks for parallel execution across multiple subAgents
---

# Parallel Task Decomposition

## Overview

Decompose complex tasks into independent subtasks that can execute in parallel across multiple subAgents. The main agent orchestrates dispatch, monitors progress, and integrates results.

**Core Principle:**
```
Big Task → Analyze Dependencies → Decompose → Parallel Dispatch → Integrate Results
```

**When to Use:**
- Task touches multiple independent modules/files
- No sequential dependencies between components
- Each subtask has clear, isolated scope
- Speed matters (parallel execution is faster)

**When NOT to Use:**
- Heavy sequential dependencies (each step needs previous output)
- Shared state that cannot be isolated
- Tasks requiring real-time coordination
- Small tasks where overhead exceeds benefit

## Task Decomposition Framework

### Step 1: Dependency Analysis

Before decomposition, analyze the task dependency graph:

```
┌─────────────────────────────────────────┐
│           Task Analysis                 │
│  ┌─────────┐       ┌─────────┐          │
│  │ Module A│◄─────►│ Module B│  Shared? │
│  └────┬────┘       └────┬────┘          │
│       │                 │               │
│       ▼                 ▼               │
│  ┌─────────┐       ┌─────────┐          │
│  │ Module C│◄─────►│ Module D│  Shared? │
│  └─────────┘       └─────────┘          │
└─────────────────────────────────────────┘
```

**Questions to Ask:**
1. Which modules/files are involved?
2. Do they share mutable state?
3. Are there read-only shared dependencies?
4. Can outputs be produced independently?

### Step 2: Define Task Boundaries

**Good Boundary Criteria:**
- ✅ Single responsibility (one concern per task)
- ✅ No mutable shared state
- ✅ Clear input/output contract
- ✅ Can be verified independently
- ✅ Idempotent (rerunnable without side effects)

**Boundary Definition Template:**
```typescript
interface SubTask {
  id: string;                    // Unique identifier
  scope: string;                 // What this task owns
  inputs: string[];              // Required inputs
  outputs: string[];             // Produced outputs
  readonly_deps: string[];       // Read-only shared dependencies
  invariant: string;             // Pre/post conditions
}
```

### Step 3: Dependency Graph Construction

```typescript
// Example: Implementing a REST API with auth, CRUD, and validation

const tasks: SubTask[] = [
  {
    id: 'auth-middleware',
    scope: 'src/middleware/auth.ts',
    inputs: ['JWT secret', 'User model'],
    outputs: ['auth middleware function'],
    readonly_deps: ['src/types/auth.d.ts'],
    invariant: 'Produces auth(req, res, next) that validates JWT'
  },
  {
    id: 'user-model',
    scope: 'src/models/user.ts',
    inputs: ['Database schema'],
    outputs: ['User model class', 'TypeScript interfaces'],
    readonly_deps: ['src/types/user.d.ts'],
    invariant: 'User.create(), User.find(), User.validate() work'
  },
  {
    id: 'user-routes',
    scope: 'src/routes/user.ts',
    inputs: ['User model', 'Auth middleware', 'Validation schemas'],
    outputs: ['Express router with CRUD endpoints'],
    readonly_deps: ['src/types/*.d.ts'],
    invariant: 'Routes handle GET/POST/PUT/DELETE /users'
  },
  {
    id: 'validation-schemas',
    scope: 'src/validation/user.ts',
    inputs: ['User interface definition'],
    outputs: ['Zod schemas for user validation'],
    readonly_deps: ['src/types/user.d.ts'],
    invariant: 'Schemas validate user input correctly'
  }
];

// Dependency graph
const dependencies = {
  'auth-middleware': [],           // Can start immediately
  'user-model': [],                // Can start immediately
  'validation-schemas': [],        // Can start immediately
  'user-routes': ['user-model', 'auth-middleware', 'validation-schemas']
};
```

### Step 4: Execution Scheduling

```
Phase 1 (Parallel):    auth-middleware + user-model + validation-schemas
                              │              │               │
                              ▼              ▼               ▼
Phase 2 (Sequential):     user-routes (waits for all Phase 1)
```

## Parallel Dispatch Patterns

### Pattern 1: Fully Parallel (No Dependencies)

All subtasks independent - dispatch simultaneously:

```typescript
// All tasks can run in parallel
const tasks = ['task-a', 'task-b', 'task-c', 'task-d'];

const taskIds = tasks.map(taskId => 
  task(
    category="quick",
    run_in_background=true,
    description=`Execute ${taskId}`,
    prompt=buildPrompt(taskId)
  )
);

// Wait for all to complete
const results = await Promise.all(
  taskIds.map(id => background_output(task_id=id))
);

// Integrate results
const finalResult = integrate(results);
```

### Pattern 2: Phased Execution (Dependencies)

Execute in phases based on dependency graph:

```typescript
// Phase 1: Foundation tasks (no dependencies)
const phase1Tasks = ['user-model', 'auth-middleware', 'validation-schemas'];
const phase1Ids = phase1Tasks.map(t => task(/* ... */));

// Wait for Phase 1
await Promise.all(phase1Ids.map(id => background_output(task_id=id)));

// Phase 2: Dependent tasks
const phase2Tasks = ['user-routes'];
const phase2Ids = phase2Tasks.map(t => task(/* ... */));

// Wait for Phase 2
await Promise.all(phase2Ids.map(id => background_output(task_id=id)));
```

### Pattern 3: Dynamic Scheduling

Start tasks as dependencies complete:

```typescript
const pending = new Set(['auth', 'model', 'validation', 'routes']);
const running = new Set<string>();
const completed = new Set<string>();
const taskResults = new Map<string, any>();

async function scheduleReadyTasks() {
  const ready = [...pending].filter(taskId => 
    dependencies[taskId].every(dep => completed.has(dep))
  );
  
  for (const taskId of ready) {
    pending.delete(taskId);
    running.add(taskId);
    
    const taskPromise = task(
      category="quick",
      run_in_background=true,
      description=`Execute ${taskId}`,
      prompt=buildPrompt(taskId, taskResults)
    );
    
    // Handle completion
    taskPromise.then(result => {
      running.delete(taskId);
      completed.add(taskId);
      taskResults.set(taskId, result);
      
      // Schedule newly ready tasks
      scheduleReadyTasks();
    });
  }
}

// Start scheduling
scheduleReadyTasks();

// Wait for all to complete
await waitUntil(() => pending.size === 0 && running.size === 0);
```

## State Isolation Strategies

### Strategy 1: Copy-on-Write

Each subAgent gets its own copy of shared read-only data:

```typescript
// Main agent provides read-only context
const sharedContext = {
  types: readFile('src/types/index.ts'),
  config: readFile('config/app.json'),
  constants: readFile('src/constants.ts')
};

// Each subAgent gets a copy (no shared mutable state)
const taskA = task(
  category="quick",
  run_in_background=true,
  description="Implement module A",
  prompt:`
    CONTEXT (read-only copy):
    ${JSON.stringify(sharedContext, null, 2)}
    
    TASK: Implement src/modules/A.ts
    RULES:
    - Do not modify files outside your scope
    - Use provided types and constants
    - Return only your output files
  `
);
```

### Strategy 2: Interface Contracts

Define clear contracts instead of sharing implementation:

```typescript
// Define interface, not implementation
interface IUserService {
  findById(id: string): Promise<User | null>;
  create(user: CreateUserDTO): Promise<User>;
}

// SubTask 1: Implement the interface
const implTask = task(
  prompt:`
    Implement IUserService in src/services/user.ts
    Interface definition: ${JSON.stringify(userServiceInterface)}
  `
);

// SubTask 2: Use the interface (doesn't care about implementation)
const consumerTask = task(
  prompt:`
    Implement user controller using IUserService
    Assume IUserService is already implemented and working
    Import from: src/services/user
  `
);
```

### Strategy 3: Worktree Isolation

Use Git worktrees for complete isolation:

```typescript
// Create isolated worktrees for each subtask
const worktrees = await Promise.all([
  createWorktree('task-a'),
  createWorktree('task-b'),
  createWorktree('task-c')
]);

// Run each subtask in its own worktree
const tasks = worktrees.map((wt, i) =>
  task(
    category="quick",
    run_in_background=true,
    description=`Task ${i}`,
    prompt:`Execute in worktree: ${wt.path}\n${taskPrompts[i]}`
  )
);

// Merge results back
await mergeWorktrees(worktrees);
```

## Result Integration Patterns

### Pattern 1: File-Based Integration

Each subtask produces files, merge at filesystem level:

```typescript
// Collect output files from all subAgents
const outputs = await collectOutputs(taskIds);

// Validate no conflicts
const conflicts = findConflictingFiles(outputs);
if (conflicts.length > 0) {
  throw new Error(`File conflicts: ${conflicts}`);
}

// Write all files to workspace
for (const output of outputs) {
  writeFile(output.path, output.content);
}

// Run final verification
await runTests();
```

### Pattern 2: Semantic Merge

Merge based on code structure (classes, functions):

```typescript
// Parse outputs into ASTs
const asts = outputs.map(parseAST);

// Check for conflicting symbols
const symbols = extractAllSymbols(asts);
const duplicates = findDuplicates(symbols);

if (duplicates.length > 0) {
  // Reconcile duplicates
  await reconcileDuplicates(duplicates);
}

// Generate merged output
const merged = generateMergedCode(asts);
writeFile('output.ts', merged);
```

### Pattern 3: Sequential Integration

Integrate results one at a time, handling conflicts:

```typescript
let integratedResult = initialState;

for (const taskId of taskIds) {
  const result = await background_output(task_id=taskId);
  
  // Merge with existing results
  integratedResult = await merge(integratedResult, result, {
    onConflict: async (conflict) => {
      // Dispatch resolution subtask
      return await task(
        category="quick",
        prompt:`Resolve merge conflict: ${conflict.description}`
      );
    }
  });
}
```

## Decomposition Checklist

Before dispatching parallel subtasks, verify:

- [ ] **Scope Clarity** - Each subtask has clear, non-overlapping scope
- [ ] **No Mutable Shared State** - Subtasks don't modify same data
- [ ] **Dependency Order** - Dependencies form DAG (no cycles)
- [ ] **Idempotency** - Can rerun subtask without side effects
- [ ] **Verifiability** - Each subtask has clear success criteria
- [ ] **Output Contracts** - Clear definition of what each subtask produces

## Common Anti-Patterns

### ❌ Tight Coupling
```typescript
// BAD: Tasks modify same file
taskA: modify src/app.ts lines 1-50
taskB: modify src/app.ts lines 40-90  // CONFLICT!
```

### ✅ Proper Separation
```typescript
// GOOD: Each task owns separate files
taskA: create src/feature-a/module.ts
taskB: create src/feature-b/module.ts
taskC: create src/integration.ts (imports both)
```

### ❌ Hidden Dependencies
```typescript
// BAD: Task B assumes Task A's side effect
taskA: sets global.config.value = 'x'
taskB: reads global.config.value  // Implicit dependency!
```

### ✅ Explicit Contracts
```typescript
// GOOD: Explicit input/output
taskA: returns { config: { value: 'x' } }
taskB: prompt includes "Config value: 'x'"  // Explicit
```

## Template: Complete Parallel Workflow

```typescript
// ============================================================
// COMPLETE PARALLEL TASK DECOMPOSITION WORKFLOW
// ============================================================

// 1. ANALYZE AND DECOMPOSE
const taskAnalysis = {
  components: [
    { id: 'auth', scope: 'src/auth/', deps: [] },
    { id: 'database', scope: 'src/db/', deps: [] },
    { id: 'api', scope: 'src/api/', deps: ['auth', 'database'] },
    { id: 'tests', scope: 'tests/', deps: ['api'] }
  ]
};

// 2. SCHEDULE PHASES
const phases = computeExecutionPhases(taskAnalysis.components);

for (const phase of phases) {
  console.log(`Executing phase: ${phase.name}`);
  
  // Dispatch all tasks in phase in parallel
  const taskIds = phase.tasks.map(t =>
    task(
      category="quick",
      load_skills=[/* relevant skills */],
      run_in_background=true,
      description=`${t.id}: ${t.scope}`,
      prompt: buildSubTaskPrompt(t, context)
    )
  );
  
  // Wait for phase completion
  const results = await Promise.all(
    taskIds.map(id => background_output(task_id=id))
  );
  
  // Validate phase results
  for (const result of results) {
    if (!validateResult(result)) {
      throw new Error(`Phase ${phase.name} validation failed`);
    }
  }
  
  // Update context for next phase
  updateContext(results);
}

// 3. INTEGRATE RESULTS
const finalOutput = await integrateAllPhases(phases);

// 4. FINAL VERIFICATION
await runFinalVerification(finalOutput);

console.log('✅ Parallel task decomposition complete');
```

## Best Practices

1. **Start Small** - Decompose into 2-3 subtasks first, gain confidence
2. **Clear Ownership** - Each file/module owned by exactly one subtask
3. **Explicit Contracts** - Document inputs/outputs in prompts
4. **Fail Fast** - Validate subtask outputs immediately
5. **Idempotent Design** - Subtasks should be rerunnable
6. **Minimal Coordination** - Avoid real-time coordination between subtasks
7. **Result Caching** - Cache subtask results to avoid recomputation
