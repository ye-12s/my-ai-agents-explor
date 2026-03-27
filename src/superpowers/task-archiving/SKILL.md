---
name: task-archiving
description: Use when completing a development task to archive implementation details, design decisions, and lessons learned for future traceability
---

# Task Archiving

## Overview

Archive completed tasks to `docs/arch/` with structured documentation for traceability. Each archive entry captures what was changed, why it was needed, and when to apply similar solutions.

**Two Modes:**

1. **Optional Archiving** (default) - Manually trigger after task completion
2. **Mandatory Archiving** (workspace-level) - Automatically enforced for configured workspaces

**When to Archive:**
- After task completion and verification
- After code review approval
- Before merging/closing a feature branch

**Value:**
- ✅ Prevents repeated mistakes
- ✅ Accelerates similar future tasks
- ✅ Documents "why" not just "what"
- ✅ Builds organizational knowledge

## Quick Start

### Option 1: Optional Archiving (Single Task)

Use SubAgent after completing a task:

```typescript
const archiveTask = task(
  category="writing",
  load_skills=["superpowers/task-archiving"],
  run_in_background=false,
  description="Archive completed task",
  prompt:`Create archive for the feature I just implemented...`
);
```

### Option 2: Mandatory Archiving (Workspace-Level)

**Enable automatic archiving for entire workspace:**

```bash
# Run in project root
~/.agents/skills/superpowers/task-archiving/init-workspace-archive.sh
```

This creates `.arch-config.yml` - once present, **all tasks in this workspace must be archived**.

**Agent Behavior:**
- Detects `.arch-config.yml` automatically
- Forces archiving after every qualifying task
- Blocks task completion until archive is valid

**See:** `workspace-mandatory-archiving/` for full documentation.

## Archive Structure

```
docs/arch/
├── YYYY-MM-DD-feature-name.md          # Individual task archives
├── index.md                             # Auto-generated index
└── templates/
    └── archive-template.md              # Template for new archives
```

## Archive Document Format

```markdown
# [Feature/Task Name]

**Archive Date:** YYYY-MM-DD HH:MM  
**Related Tickets:** #123, PR #456  
**Author:** @username  
**Status:** ✅ Completed / ⚠️ Partial / ❌ Reverted

---

## Summary

One-paragraph description of what was implemented.

## Problem Statement

What problem did this solve? Why was it needed?

- Context that led to this change
- Pain points before the solution
- Constraints and requirements

## Solution Overview

High-level approach and key decisions.

### Files Changed

| File | Change Type | Purpose |
|------|-------------|---------|
| `src/module/file.ts` | Modify | Added validation logic |
| `src/module/new.ts` | Create | New utility class |
| `tests/...` | Create | Unit tests |

### Key Implementation Details

```typescript
// Critical code snippet with explanation
const keyInsight = 'Why this approach was chosen';
```

## Technical Decisions

### Decision 1: [Topic]
**Chosen:** Option A  
**Alternatives Considered:** Option B, Option C  
**Rationale:** Why A was better for this context  
**Trade-offs:** What we gave up

### Decision 2: [Topic]
...

## Lessons Learned

### What Worked Well
- Approach that succeeded
- Tool that helped
- Pattern to reuse

### What Didn't Work
- Failed attempt and why
- Misconception corrected
- Anti-pattern to avoid

### Surprises
- Unexpected complication
- Insight gained

## Applicability

### When to Use This Approach
✅ Use when:
- Specific condition 1
- Specific condition 2

### When NOT to Use
❌ Avoid when:
- Different condition 1
- Different condition 2

### Related Archives
- [YYYY-MM-DD-related-feature](link) - Similar problem, different solution
- [YYYY-MM-DD-another-feature](link) - Builds on this approach

## References

- Design doc: `docs/design/feature.md`
- API docs: `docs/api/...`
- External resources: links
```

## Quick Archive (SubAgent Pattern)

Delegate archive creation to a subAgent to keep main context clean:

```typescript
// After task completion
const archiveTask = task(
  category="writing",
  load_skills=["superpowers/task-archiving"],
  run_in_background=false,
  description="Create task archive",
  prompt=`
    TASK: Create archive document for completed feature
    
    ARCHIVE LOCATION: docs/arch/2024-03-27-feature-name.md
    
    TASK SUMMARY:
    - Feature: [name]
    - Files changed: [list]
    - Problem solved: [description]
    
    KEY DECISIONS MADE:
    1. [Decision and rationale]
    2. [Decision and rationale]
    
    LESSONS LEARNED:
    - [What worked]
    - [What didn't]
    
    REQUIREMENTS:
    1. Use the archive template from docs/arch/templates/archive-template.md
    2. Include all sections: Summary, Problem, Solution, Decisions, Lessons
    3. Be specific about applicability - when to use/not use this approach
    4. Link to related files, PRs, tickets
    5. Write for future developers (including yourself in 6 months)
  `
);
```

## Manual Archive Creation

If not using subAgent:

1. **Create archive file:**
   ```bash
   date +%Y-%m-%d > docs/arch/$(date +%Y-%m-%d)-feature-name.md
   ```

2. **Fill template** (copy from `docs/arch/templates/archive-template.md`)

3. **Update index** (if maintaining manual index)

## Best Practices

### Content Quality
- **Be specific:** "Use X when Y" not "This might help sometimes"
- **Include failures:** Document what you tried that didn't work
- **Link liberally:** Connect to code, docs, tickets, other archives
- **Code snippets:** Include minimal working examples

### Maintenance
- **Review old archives** quarterly for accuracy
- **Update status** if implementation is later changed/reverted
- **Cross-reference:** Link related archives bidirectionally

### Automation Hooks

**Pre-commit hook** (optional):
```bash
#!/bin/bash
# .git/hooks/pre-commit
if git diff --cached --name-only | grep -q "^src/"; then
  echo "⚠️  Remember to update docs/arch/ if this is a significant change"
fi
```

**GitHub Action** (optional):
```yaml
# .github/workflows/archive-reminder.yml
name: Archive Reminder
on:
  pull_request:
    types: [closed]
jobs:
  remind:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '📁 Consider creating an archive entry in `docs/arch/` for traceability'
            })
```

## Workspace Mandatory Archiving

For teams/projects requiring **strict** archival discipline.

### Setup

```bash
# Run in project root
~/.agents/skills/superpowers/task-archiving/init-workspace-archive.sh
```

This creates:
- `.arch-config.yml` - Configuration file
- `docs/arch/` - Archive directory with templates

### How It Works

Once `.arch-config.yml` exists in workspace:

1. **Agent auto-detects** configuration on entry
2. **All qualifying tasks** must be archived
3. **Archive validation** ensures completeness
4. **Task completion blocked** until archive is valid

### Agent Behavior

```typescript
// Agent detects .arch-config.yml
const config = detectWorkspaceConfig();

if (config?.archiving?.enabled) {
  // Enter mandatory mode
  enableMandatoryArchiving(config);
  
  // After every task
  onTaskComplete = async (task) => {
    // FORCE archive creation
    await createMandatoryArchive(task, config);
    
    // VALIDATE archive
    if (!validateArchive(config)) {
      throw new Error('Archive validation failed');
    }
    
    return task;
  };
}
```

### Configuration Options

See `workspace-mandatory-archiving/SKILL.md` for full documentation.

Quick config (`.arch-config.yml`):

```yaml
archiving:
  enabled: true
  directory: docs/arch
  triggers:
    min_files_changed: 1
    exclude_paths:
      - "*.log"
      - "node_modules/**"
  requirements:
    required_fields:
      - Summary
      - Problem Statement
      - Solution
      - Technical Decisions
      - Lessons Learned
      - Applicability
```

## Archive Index Template

```markdown
# Architecture Decision Index

**Last Updated:** YYYY-MM-DD

## By Date

| Date | Feature | Status | Key Tech |
|------|---------|--------|----------|
| 2024-03-27 | Feature A | ✅ | React, GraphQL |
| 2024-03-20 | Feature B | ⚠️ | Python, Redis |

## By Topic

### Frontend
- [2024-03-27-feature-a](link) - Component architecture

### Backend
- [2024-03-20-feature-b](link) - Caching strategy

## Common Patterns

### Authentication
See: [2024-03-15-auth-refactor](link)

### Database Migrations
See: [2024-03-10-migration-strategy](link)
```
