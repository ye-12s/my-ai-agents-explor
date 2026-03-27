---
name: discussion-context-hook
description: Use when delegating tasks to subAgents to preserve and pass the current discussion context, user intent, and constraints
---

# Discussion Context Hook

## Overview

Preserve the full context of the current discussion when dispatching subAgents. Prevents context loss between main agent and subAgents, ensuring continuity and alignment with user intent.

**Problem:**
- SubAgents lack awareness of earlier discussion points
- User constraints and preferences get lost
- Decisions made earlier are forgotten
- SubAgents may contradict established direction

**Solution:**
- Automatically capture discussion context
- Pass summarized context to every subAgent
- Maintain continuity across parallel tasks
- Reference back to original user requests

## Context Capture Framework

### What to Capture

```typescript
interface DiscussionContext {
  // Original user request
  originalRequest: {
    timestamp: string;
    content: string;
    intent: string;        // What user wants to achieve
    constraints: string[]; // Must/must-not rules
  };
  
  // Discussion evolution
  evolution: {
    clarifications: string[];    // Questions asked and answered
    decisions: string[];         // Agreements reached
    pivots: string[];           // Changes in direction
    rejections: string[];       // Approaches user rejected
  };
  
  // Current state
  currentState: {
    phase: 'planning' | 'implementing' | 'reviewing' | 'complete';
    completedTasks: string[];
    pendingTasks: string[];
    blockers: string[];
  };
  
  // User preferences
  preferences: {
    style: 'concise' | 'detailed' | 'tutorial';
    priorities: string[];       // What matters most to user
    antiPatterns: string[];     // What user dislikes
  };
  
  // Technical constraints
  constraints: {
    mustUse: string[];          // Required technologies
    mustNotUse: string[];       // Forbidden approaches
    compatibility: string[];    // Must work with existing code
  };
}
```

## Context Preservation Patterns

### Pattern 1: Full Context Pass

Pass complete discussion history to subAgent:

```typescript
function createContextualTask(subTask, fullContext) {
  return task({
    category: subTask.category,
    load_skills: subTask.skills,
    run_in_background: subTask.background,
    description: subTask.description,
    prompt: `
      ============================================================
      DISCUSSION CONTEXT (PRESERVE THIS)
      ============================================================
      
      ORIGINAL USER REQUEST:
      "${fullContext.originalRequest.content}"
      
      USER INTENT:
      ${fullContext.originalRequest.intent}
      
      CONSTRAINTS:
      ${fullContext.originalRequest.constraints.map(c => `  - ${c}`).join('\n')}
      
      DECISIONS MADE SO FAR:
      ${fullContext.evolution.decisions.map(d => `  ✓ ${d}`).join('\n')}
      
      APPROACHES REJECTED:
      ${fullContext.evolution.rejections.map(r => `  ✗ ${r}`).join('\n')}
      
      CURRENT PHASE: ${fullContext.currentState.phase}
      
      USER PREFERENCES:
      - Style: ${fullContext.preferences.style}
      - Priorities: ${fullContext.preferences.priorities.join(', ')}
      
      ============================================================
      YOUR TASK
      ============================================================
      
      ${subTask.prompt}
      
      ============================================================
      REMINDERS
      ============================================================
      - Stay aligned with user intent stated above
      - Respect all constraints and rejected approaches
      - Match user's preferred style (${fullContext.preferences.style})
      - If unclear, reference back to original request
    `
  });
}
```

### Pattern 2: Minimal Context Pass

Pass only essential context for simple tasks:

```typescript
function createMinimalContextTask(subTask, essentialContext) {
  return task({
    ...subTask,
    prompt: `
      CONTEXT:
      Original request: "${essentialContext.originalRequest}"
      Key constraint: ${essentialContext.keyConstraint}
      User style: ${essentialContext.style}
      
      YOUR TASK:
      ${subTask.prompt}
    `
  });
}
```

### Pattern 3: Context Checkpoint

Save context at key points for later reference:

```typescript
// After major discussion milestones
const checkpoint = {
  id: 'post-architecture-decision',
  timestamp: new Date().toISOString(),
  summary: captureDiscussionSummary(),
  decisions: extractDecisions(),
  nextSteps: identifyNextSteps()
};

// Pass checkpoint ID to subAgents
function taskWithCheckpoint(subTask, checkpointId) {
  return task({
    prompt: `
      REFERENCE CHECKPOINT: ${checkpointId}
      
      This task continues from discussion checkpoint "${checkpointId}".
      Key decisions from that point:
      ${getCheckpointDecisions(checkpointId)}
      
      ${subTask.prompt}
    `
  });
}
```

## Implementation Templates

### Template 1: Parallel Tasks with Shared Context

```typescript
// Main agent: Capture full context once
const discussionContext = {
  originalRequest: {
    content: userMessage,
    intent: extractIntent(userMessage),
    constraints: extractConstraints(userMessage)
  },
  evolution: {
    decisions: collectedDecisions,
    rejections: rejectedApproaches
  },
  preferences: {
    style: detectUserStyle(),
    priorities: userPriorities
  }
};

// Dispatch parallel tasks with same context
const tasks = [
  {
    id: 'task-a',
    category: 'quick',
    prompt: 'Implement feature A...'
  },
  {
    id: 'task-b', 
    category: 'quick',
    prompt: 'Implement feature B...'
  }
];

const taskIds = tasks.map(t => 
  createContextualTask(t, discussionContext)
);
```

### Template 2: Chained Tasks with Evolving Context

```typescript
// Phase 1 with initial context
const phase1Context = buildInitialContext();
const phase1Result = await task({
  prompt: wrapWithContext('Do phase 1...', phase1Context)
});

// Update context with phase 1 outcomes
const phase2Context = evolveContext(phase1Context, phase1Result);
const phase2Result = await task({
  prompt: wrapWithContext('Do phase 2...', phase2Context)
});

// Continue with enriched context
const phase3Context = evolveContext(phase2Context, phase2Result);
```

### Template 3: Context Recovery

When context might be lost (long-running tasks):

```typescript
function recoverableTask(subTask, contextBackup) {
  return task({
    prompt: `
      CONTEXT RECOVERY:
      This task may have lost context due to [reason].
      
      ORIGINAL DISCUSSION:
      ${contextBackup.summary}
      
      USER INTENT:
      ${contextBackup.intent}
      
      If this task seems misaligned with the above,
      STOP and request clarification rather than proceeding.
      
      TASK:
      ${subTask.prompt}
    `
  });
}
```

## Context Extractors

### Extract User Intent

```typescript
function extractIntent(userMessage: string): string {
  const patterns = [
    /I want to (.+)/i,
    /I need (.+)/i,
    /Can you (.+)/i,
    /Help me (.+)/i,
    /How do I (.+)/i
  ];
  
  for (const pattern of patterns) {
    const match = userMessage.match(pattern);
    if (match) return match[1];
  }
  
  return 'Not explicitly stated - analyze message';
}
```

### Extract Constraints

```typescript
function extractConstraints(discussion: string[]): string[] {
  const constraintPatterns = [
    /must|need to|have to/gi,
    /cannot|can't|must not/gi,
    /should|ought to/gi,
    /don't want|avoid/gi
  ];
  
  const constraints = [];
  
  for (const message of discussion) {
    for (const pattern of constraintPatterns) {
      const matches = message.match(new RegExp(`${pattern.source} (.+)`, 'gi'));
      if (matches) {
        constraints.push(...matches);
      }
    }
  }
  
  return [...new Set(constraints)]; // Deduplicate
}
```

### Detect User Style

```typescript
function detectUserStyle(): 'concise' | 'detailed' | 'tutorial' {
  const userMessages = getUserMessages();
  
  // Count indicators
  const detailedIndicators = userMessages.filter(m => 
    m.length > 100 || 
    m.includes('explain') || 
    m.includes('detail')
  ).length;
  
  const conciseIndicators = userMessages.filter(m =>
    m.length < 50 ||
    m.includes('quick') ||
    m.includes('brief')
  ).length;
  
  if (detailedIndicators > conciseIndicators) return 'detailed';
  if (conciseIndicators > detailedIndicators) return 'concise';
  return 'tutorial'; // Default
}
```

## Context Validation

### Check Context Alignment

```typescript
function validateContextAlignment(subAgentOutput, originalContext) {
  const checks = {
    // Does output respect constraints?
    constraintsRespected: checkConstraints(subAgentOutput, originalContext.constraints),
    
    // Does output match user style?
    styleMatch: checkStyle(subAgentOutput, originalContext.preferences.style),
    
    // Does output align with intent?
    intentAlignment: checkIntent(subAgentOutput, originalContext.originalRequest.intent),
    
    // Any rejected approaches used?
    noRejectedPatterns: !containsRejectedPatterns(subAgentOutput, originalContext.evolution.rejections)
  };
  
  const failedChecks = Object.entries(checks)
    .filter(([_, passed]) => !passed)
    .map(([name, _]) => name);
  
  if (failedChecks.length > 0) {
    console.warn(`Context alignment issues: ${failedChecks.join(', ')}`);
    return { valid: false, issues: failedChecks };
  }
  
  return { valid: true };
}
```

## Best Practices

### DO
- ✅ Capture context at discussion start
- ✅ Update context after major decisions
- ✅ Pass relevant constraints to every subAgent
- ✅ Reference original user intent in prompts
- ✅ Validate subAgent outputs against context

### DON'T
- ❌ Assume subAgents remember earlier discussion
- ❌ Pass full conversation history (too long)
- ❌ Ignore user preferences in subAgent outputs
- ❌ Forget rejected approaches
- ❌ Let context grow unbounded

## Integration with Other Skills

### With Parallel Task Decomposition

```typescript
// Combine with parallel-task-decomposition
const context = captureDiscussionContext();

const decomposition = await task({
  load_skills: ['superpowers/parallel-task-decomposition'],
  prompt: `
    Decompose this task considering:
    USER INTENT: ${context.originalRequest.intent}
    CONSTRAINTS: ${context.originalRequest.constraints}
    
    [task description]
  `
});

// Each subtask gets context
const tasks = decomposition.subtasks.map(st =>
  createContextualTask(st, context)
);
```

### With Task Archiving

```typescript
// Archive includes full context
const archiveEntry = {
  ...taskResults,
  discussionContext: {
    originalRequest: context.originalRequest,
    keyDecisions: context.evolution.decisions,
    userPreferences: context.preferences
  }
};
```

## Quick Reference

### Minimal Implementation

```typescript
// 1. Capture once
const context = {
  original: userRequest,
  constraints: ['use TypeScript', 'no external deps'],
  style: 'concise'
};

// 2. Wrap every subAgent prompt
function contextualPrompt(task, ctx) {
  return `
    Context: ${ctx.original}
    Constraints: ${ctx.constraints.join(', ')}
    Style: ${ctx.style}
    
    Task: ${task}
  `;
}

// 3. Use for all subAgents
const taskId = task({
  prompt: contextualPrompt('Do X...', context)
});
```
