# Workspace Mandatory Archiving Example

This is an example workspace configuration for mandatory task archiving.

## Files

### `.arch-config.yml`

```yaml
archiving:
  enabled: true
  directory: docs/arch
  
  triggers:
    on_file_change:
      - create
      - modify
    min_files_changed: 1
    exclude_paths:
      - "*.log"
      - ".git/**"
      - "node_modules/**"
  
  requirements:
    required_fields:
      - Summary
      - Problem Statement
      - Solution
      - Technical Decisions
      - Lessons Learned
      - Applicability
    min_description_length: 100
  
  metadata:
    capture_git_info: true
    capture_changed_files: true
    capture_author: true
```

## Agent Behavior

When an Agent enters this workspace:

1. **Detection:** Agent reads `.arch-config.yml`
2. **Activation:** If `enabled: true`, mandatory mode activates
3. **Enforcement:** After each task, Agent **must** create archive

### Example Session

```
User: Implement user authentication

Agent: Working on authentication...
      [implements feature]
      
Agent: ✅ Implementation complete
      📝 Creating mandatory archive...
      
Agent: Archive created: docs/arch/2024-03-27-user-authentication.md
      Task complete.
```

## Archive Output

After task completion, the following is automatically created:

```markdown
# User Authentication

**Archive Date:** 2024-03-27 14:30  
**Related Tickets:** #42  
**Author:** @agent  
**Status:** ✅ Completed

---

## Summary

Implemented JWT-based user authentication with refresh tokens.

## Problem Statement

The application needed secure user authentication with:
- Stateless sessions (no server-side storage)
- Token refresh capability
- Role-based access control

## Solution Overview

### Files Changed

| File | Change Type | Purpose |
|------|-------------|---------|
| `src/auth/jwt.ts` | Create | JWT token utilities |
| `src/auth/middleware.ts` | Create | Authentication middleware |
| `src/routes/login.ts` | Modify | Add login endpoint |
| `tests/auth.test.ts` | Create | Unit tests |

### Key Implementation Details

```typescript
// Token generation with expiration
const token = jwt.sign(
  { userId: user.id, role: user.role },
  SECRET,
  { expiresIn: '15m' }
);
```

## Technical Decisions

### Decision 1: JWT vs Session-based
**Chosen:** JWT with refresh tokens  
**Alternatives:** Server-side sessions (Redis), Simple JWT  
**Rationale:** Stateless scales better, refresh tokens provide security  
**Trade-offs:** Token revocation more complex

## Lessons Learned

### What Worked Well
- Using jsonwebtoken library saved time
- Separating auth middleware made testing easier

### What Didn't Work
- Initial attempt with custom crypto was error-prone
- First design had tokens that were too long-lived

## Applicability

### When to Use This Approach
✅ Use when:
- Building API-first applications
- Need horizontal scalability
- Multiple client types (web, mobile, desktop)

### When NOT to Use
❌ Avoid when:
- Immediate token revocation is critical
- Session affinity is acceptable
- Building traditional server-rendered apps

### Related Archives
- None yet

## References

- Design doc: `docs/design/auth.md`
- Library: https://github.com/auth0/node-jsonwebtoken
```

## Disable Mandatory Archiving

To disable:

```bash
rm .arch-config.yml
```

Or edit and set `enabled: false`.
