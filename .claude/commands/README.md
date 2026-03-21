# Agent Slash Commands

This directory contains slash commands for invoking specialized agents in the FitTrack development workflow.

## Available Agents

### `/ba` - Business Analyst
**When to use:** Starting a new feature, gathering requirements
**Example:**
```
/ba I want to add a nutrition tracking feature
```

### `/sa` - Solutions Architect
**When to use:** After requirements are approved, need technical design
**Example:**
```
/sa Design the nutrition tracking feature based on PRD #XYZ
```

### `/developer` - Flutter Developer
**When to use:** Implementing features with approved designs
**Example:**
```
/developer Implement task #45 from the nutrition tracking feature
```

### `/testing` - Testing Agent
**When to use:** After implementation, need to run tests
**Example:**
```
/testing Implementation complete for nutrition tracking. Parent Issue: #45, PR: #46
```

### `/security-audit` - Security Audit Agent
**When to use:** After tests pass, before QA begins (automatic handoff from Testing)
**Example:**
```
/security-audit Testing complete for nutrition tracking. Parent Issue: #45, all tests passing.
```

### `/accessibility-audit` - Accessibility Audit Agent
**When to use:** After security audit passes (automatic handoff from Security Audit)
**Example:**
```
/accessibility-audit Security audit passed for nutrition tracking. Parent Issue: #45.
```

### `/qa` - QA Agent
**When to use:** After accessibility audit passes, manual device testing
**Example:**
```
/qa Accessibility audit passed for nutrition tracking. Parent Issue: #45. Beta build: [URL]
```

### `/appstore-prep` - App Store Prep Agent
**When to use:** After QA approval and user sign-off, prepare store submission assets
**Example:**
```
/appstore-prep QA approved for nutrition tracking. Parent Issue: #45. Version: 1.7.0
```

### `/deployment` - Deployment Agent
**When to use:** After store assets ready and user approval, release to production
**Example:**
```
/deployment Store assets ready for nutrition tracking. Parent Issue: #45. Version: 1.7.0
```

## Workflow

```
User Request
    ↓
/ba (gather requirements)
    ↓
User Approval
    ↓
/sa (create design)
    ↓
User Approval
    ↓
/developer (implement)
    ↓
/testing (run tests)          ← automatic
    ↓
/security-audit               ← automatic
    ↓
/accessibility-audit          ← automatic
    ↓
/qa (manual device testing)   ← automatic
    ↓
User Approval
    ↓
/appstore-prep                ← automatic after approval
    ↓
User Approval
    ↓
/deployment (release)
```

## Usage Notes

- Invoke agents by typing `/agent-name` followed by your request
- Agents automatically follow the workflow defined in `.claude/agents/`
- Some handoffs require user approval (BA→SA, SA→Developer, QA→AppStorePrep, AppStorePrep→Deployment)
- Other handoffs are automatic (Developer→Testing→SecurityAudit→AccessibilityAudit→QA)

## Agent Files

Full agent instructions are in `.claude/agents/`:
- `ba.md` - Business Analyst
- `sa.md` - Solutions Architect
- `developer.md` - Flutter Developer
- `testing.md` - Testing Agent
- `security-audit.md` - Security Audit Agent
- `accessibility-audit.md` - Accessibility Audit Agent
- `qa.md` - QA Agent
- `appstore-prep.md` - App Store Prep Agent
- `deployment.md` - Deployment Agent
