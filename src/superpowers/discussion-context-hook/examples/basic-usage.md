# Discussion Context Hook Example

Example of preserving discussion context across parallel subAgents.

## Scenario

User asks: "I want to refactor our authentication system. Must use JWT, no external auth providers, and keep it simple. I prefer concise code with good comments."

## Without Context Hook

SubAgents lose important constraints:

```typescript
// SubAgent A (auth middleware)
taskA: "Implement auth middleware"
// Might use: OAuth, complex config, verbose code
// Violates: JWT requirement, simplicity, style

// SubAgent B (user model)
taskB: "Create user model"
// Might use: External auth provider
// Violates: "no external auth providers" constraint
```

## With Context Hook

```typescript
// Capture context from discussion
const context = {
  originalRequest: {
    content: "I want to refactor our authentication system",
    intent: "Refactor auth to be simpler and self-contained",
    constraints: [
      "Must use JWT",
      "No external auth providers",
      "Keep it simple"
    ]
  },
  preferences: {
    style: "concise",
    priorities: ["simplicity", "self-contained"]
  }
};

// SubAgent A with context
task({
  load_skills: ["superpowers/discussion-context-hook"],
  prompt: `
    CONTEXT:
    User wants to refactor auth system using JWT only (no OAuth).
    Keep code concise with good comments.
    
    TASK: Implement JWT auth middleware
    
    CONSTRAINTS:
    - Use JWT (jsonwebtoken library)
    - NO external auth providers
    - Keep it simple
    - Code should be concise
    
    YOUR OUTPUT:
    [middleware implementation]
  `
});

// SubAgent B with context
task({
  prompt: `
    CONTEXT:
    Same auth refactor project. Using JWT only, no external providers.
    
    TASK: Create user model
    
    CONSTRAINTS:
    - Local authentication only
    - Password hashing with bcrypt
    - Simple schema
    
    YOUR OUTPUT:
    [model implementation]
  `
});
```

## Result

Both subAgents respect:
- ✅ JWT requirement
- ✅ No external providers
- ✅ Simplicity constraint
- ✅ Concise style preference

## Parallel Example

```typescript
// Dispatch multiple tasks with shared context
const tasks = [
  { name: 'jwt-middleware', scope: 'src/auth/middleware.ts' },
  { name: 'user-model', scope: 'src/models/user.ts' },
  { name: 'auth-routes', scope: 'src/routes/auth.ts' },
  { name: 'token-utils', scope: 'src/auth/token.ts' }
];

const taskIds = tasks.map(t =>
  task({
    category: 'quick',
    run_in_background: true,
    description: `Implement ${t.name}`,
    prompt: buildContextualPrompt(t, context)
  })
);

// All run in parallel, all have same context
const results = await Promise.all(
  taskIds.map(id => background_output(id))
);

// Results are consistent with user requirements
```

## Context Template

```typescript
function buildContextualPrompt(subTask, context) {
  return `
    ============================================================
    USER REQUEST (from discussion)
    ============================================================
    "${context.originalRequest.content}"
    
    Intent: ${context.originalRequest.intent}
    
    Must:
    ${context.originalRequest.constraints.map(c => `  ✓ ${c}`).join('\n')}
    
    Style: ${context.preferences.style}
    
    ============================================================
    YOUR TASK: ${subTask.name}
    ============================================================
    
    ${subTask.description}
    
    Remember:
    - Stay true to user intent above
    - Respect all constraints
    - Match ${context.preferences.style} style
    - If unclear, reference original request
  `;
}
```

## Common Issues Prevented

| Issue | Without Hook | With Hook |
|-------|--------------|-----------|
| Wrong technology | Uses OAuth instead of JWT | Explicitly told "use JWT" |
| Violates constraints | Adds external provider | Reminded "no external providers" |
| Wrong style | Verbose, over-engineered | Matched to "concise" preference |
| Inconsistent | Each subAgent different | All share same context |
