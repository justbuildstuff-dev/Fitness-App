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
/testing Run full test suite for nutrition tracking feature
```

### `/qa` - QA Agent
**When to use:** After tests pass, need manual QA verification
**Example:**
```
/qa Verify nutrition tracking feature meets acceptance criteria
```

### `/deployment` - Deployment Agent
**When to use:** After QA approval, ready for production
**Example:**
```
/deployment Deploy nutrition tracking feature to production
```

## Workflow

The typical agent flow is:

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
/testing (run tests) [automatic]
    ↓
/qa (verify quality) [automatic after tests pass]
    ↓
User Approval
    ↓
/deployment (release)
```

## Usage Notes

- You can invoke agents by typing `/agent-name` followed by your request
- Agents automatically follow the workflow defined in `.claude/agents/`
- Each agent has specific responsibilities and tools (GitHub, Notion, etc.)
- Agents will hand off to the next agent when their work is complete
- Some handoffs require user approval (BA→SA, SA→Developer, QA→Deployment)
- Other handoffs are automatic (Developer→Testing, Testing→QA)

## Agent Files

The full agent instructions are stored in:
- `.claude/agents/ba.md`
- `.claude/agents/sa.md`
- `.claude/agents/developer.md`

Testing, QA, and Deployment agent instructions are embedded in their slash command files until full agent definition files are created.
