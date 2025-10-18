---
name: GitHub Workflow Management
description: Comprehensive guide for managing GitHub issues, PRs, labels, and workflow in agent-driven development
---

# GitHub Workflow Management Skill

This skill provides standardized patterns for creating issues, managing pull requests, using labels, and tracking work through the development lifecycle.

**See [Docs/Documentation_Lifecycle.md](../../Docs/Documentation_Lifecycle.md) for complete documentation lifecycle and when each type of issue/document is created.**

## Issue Creation Standards

### Feature Issues (created by BA Agent)

**Title Format:** `[Feature] Feature Name`

**Required Sections:**
```markdown
## Overview
[1-2 sentence description]

## Requirements
**Notion PRD:** [URL]

## User Stories
- As a [user], I want [goal] so that [benefit]
- [3-5 key stories from Notion]

## Acceptance Criteria
- [ ] Key criterion 1
- [ ] Key criterion 2
- [ ] Platform requirements
- [ ] Performance requirements

## Technical Notes
[Constraints, dependencies, security considerations]

## Agent Workflow
- [ ] Requirements complete (BA)
- [ ] Design complete (SA)
- [ ] Implementation complete (Dev)
- [ ] Testing complete (Testing)
- [ ] QA approved (QA)
- [ ] Deployed (Deployment)
```

**Labels:**
- `feature`
- `priority/{critical|high|medium|low}`
- `platform/{ios|android|both}`
- `area/{auth|ui|api|database|notifications}`

### Task Issues (created by SA Agent)

**Title Format:** `[Task] Specific Implementation Task`

**Required Sections:**
```markdown
## Description
[What this task implements]

## Parent Feature
Part of #[feature-issue-number]

## Implementation Steps
1. [Specific step]
2. [Specific step]
3. Write tests

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Tests written and passing
- [ ] Code coverage meets X%

## Code References
Follows pattern from: [file:line]

## Technical Design
[Link to Notion or Docs/]
```

**Labels:**
- `task`
- `ready-for-dev`
- Same priority/platform/area as parent

### Bug Issues (created by Testing or QA Agent)

**Title Format:** `[Bug] Description of Bug`

**Required Sections:**
```markdown
## Description
[What's broken]

## Related Feature
Part of #[feature-issue-number]

## Steps to Reproduce
1. Step 1
2. Step 2
3. See error

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Environment
- Platform: iOS/Android/Both
- Device: [if relevant]
- Build: [version/commit]

## Logs/Screenshots
[Error messages, screenshots]
```

**Labels:**
- `bug`
- `priority/{critical|high|medium|low}`
- `platform/{ios|android|both}`

## Issue Lifecycle Management

### Feature Issue Lifecycle

**Feature issues remain OPEN throughout entire workflow until deployment:**

1. **Created by BA** → Status: OPEN, Label: `requirements-complete`
2. **SA creates tasks** → Add child task links, Label: `ready-for-design`
3. **User approves design** → Label: `design-approved`
4. **Developer starts work** → Label: `in-development`
5. **PRs created** → Label: `in-review`
6. **All PRs merged** → Label: `ready-for-testing`
7. **Tests running** → Label: `testing`
8. **Tests pass** → Label: `ready-for-qa`
9. **QA approves** → Label: `qa-approved`
10. **Ready for production** → Label: `ready-for-deploy`
11. **Deployed to production** → Label: `deployed`, Status: CLOSED

**CRITICAL:** Only the Deployment Agent closes feature issues after production release.

### Task Issue Lifecycle

**Task issues are closed immediately after PR merged:**

1. **Created by SA** → Status: OPEN, Label: `ready-for-dev`
2. **Developer starts** → Label: `in-development`
3. **PR created** → Label: `in-review`
4. **PR merged** → Status: CLOSED (by Developer)

### Bug Issue Lifecycle

1. **Created by Testing/QA** → Status: OPEN, Label: `bug`
2. **Developer fixes** → PR created
3. **PR merged & verified** → Status: CLOSED (by Developer)

## Pull Request Standards

### PR Title Format

`[Feature] Short description (#task-number)`

Example: `[Feature] Add ThemeProvider for app theming (#10)`

### PR Description Template

```markdown
## Changes
- Implemented [feature]
- Added [functionality]
- Wrote [tests]

## Testing
- [ ] Unit tests pass
- [ ] Widget tests pass (if applicable)
- [ ] Integration tests pass (if applicable)
- [ ] No linter warnings
- [ ] Follows existing code patterns

## Design Reference
Technical Design: [Notion URL or Docs/file.md]
Follows pattern from: [file:line]

## Issue Links
Closes #[task-number]
Part of #[feature-number]
```

### PR Branch Naming

**Feature branches:**
- `feature/issue-{number}-{short-description}`
- Example: `feature/issue-10-add-shared-preferences`

**Bug fix branches:**
- `fix/issue-{number}-{short-description}`
- Example: `fix/issue-51-theme-flicker`

### PR Merge Strategy

- All PRs must pass CI checks before merging
- Squash and merge preferred for clean history
- Delete branch after merge

## Label System

### Workflow State Labels

| Label | Meaning | Who Sets |
|-------|---------|----------|
| `requirements-complete` | BA finished requirements | BA Agent |
| `ready-for-design` | Requirements approved by user | User/BA |
| `design-approved` | Design approved, ready for dev | User/SA |
| `ready-for-dev` | Task ready for implementation | SA Agent |
| `in-development` | Currently being coded | Developer |
| `in-review` | PR open, awaiting review | Developer |
| `ready-for-testing` | Code merged, ready for tests | Developer |
| `testing` | Tests running | Testing Agent |
| `ready-for-qa` | Tests passed, ready for QA | Testing Agent |
| `qa-approved` | QA passed, ready for deployment | QA Agent |
| `ready-for-deploy` | Approved for production | QA Agent |
| `deployed` | Live in production | Deployment Agent |

### Type Labels

- `feature` - New feature
- `task` - Implementation task
- `bug` - Bug report
- `epic` - Large feature spanning multiple issues

### Priority Labels

- `priority/critical` - Blocking release or severe bug
- `priority/high` - Important feature, planned for this sprint
- `priority/medium` - Planned work, not urgent
- `priority/low` - Nice-to-have, backlog item

### Platform Labels

- `platform/ios` - iOS only
- `platform/android` - Android only
- `platform/both` - Both platforms

### Area Labels

- `area/auth` - Authentication/authorization
- `area/ui` - User interface
- `area/api` - API/backend
- `area/database` - Database/Firestore
- `area/notifications` - Push notifications

## Commit Message Standards

### Format

```
[type]: [short description] (#issue-number)

[Optional longer description if needed]

Closes #[task-issue-number]
```

### Types

- `feat:` - New feature
- `fix:` - Bug fix
- `test:` - Adding tests
- `refactor:` - Code restructuring
- `docs:` - Documentation changes
- `style:` - Formatting changes
- `chore:` - Maintenance tasks

### Examples

```
feat: add ThemeProvider for app theming (#10)

Implements ChangeNotifier-based theme management with
SharedPreferences persistence following AuthProvider pattern.

Closes #10
```

```
fix: resolve theme flicker on app startup (#51)

Initialize theme synchronously before MaterialApp build
to prevent flash of wrong theme.

Closes #51
```

## Issue Linking Best Practices

### Bidirectional Links

**Parent → Child:**
```markdown
## Implementation Tasks
- #10: Add shared_preferences dependency
- #11: Create ThemeProvider
- #12: Integrate in main.dart
```

**Child → Parent:**
```markdown
## Parent Feature
Part of #1
```

### External Links

**GitHub → Notion:**
```markdown
**Notion PRD:** https://notion.so/...
```

**Notion → GitHub:**
- Set "GitHub Issue" property to issue URL

## Comment Standards

### Update Comments

When updating issue status:
```markdown
✅ [Phase] complete

[Summary of work]
- Item 1
- Item 2

[Next steps or handoff info]
```

### Handoff Comments

When handing off to another agent:
```markdown
✅ [Current phase] complete for [Feature Name]

Completed work:
- Task 1 ✓
- Task 2 ✓

Artifacts:
- PRs: #XX, #XX
- Documentation: [links]

Ready for [next agent/phase].
```

## Main Branch Protection

**CRITICAL RULES:**

- ✅ Never commit directly to main
- ✅ All changes through pull requests
- ✅ All PRs must pass CI before merge
- ❌ Direct commits will fail CI/CD
- ❌ Main branch is protected

**Why:** Main branch pushes skip tests to save CI time. All validation happens on PRs.

## GitHub Actions Integration

### Status Checks

- `all-tests-passed` - Single check for full test suite
- Unit tests
- Widget tests
- Integration tests
- Performance tests
- Security checks

### When Checks Run

- On PR creation
- On PR updates (new commits)
- NOT on main branch pushes (optimization)

### Using Status Checks

**Testing Agent should:**
1. Query `all-tests-passed` status check
2. Read logs if failed
3. Create bug issues for failures
4. Only hand off to QA if all pass

## Best Practices

### Do:
- Link all issues to parent features
- Update labels as work progresses
- Keep issue descriptions current
- Use proper commit message format
- Create focused PRs (one task per PR)
- Close task issues immediately after merge
- Keep feature issues open until deployment

### Don't:
- Close feature issues before deployment
- Create PRs without linking to issues
- Merge PRs with failing checks
- Commit directly to main branch
- Use vague issue titles or descriptions
- Skip linking to design documentation
- Leave orphaned issues without parent links

## Quick Reference

**Creating a feature issue:**
1. Use `[Feature]` prefix in title
2. Add description, user stories, acceptance criteria
3. Set labels: `feature`, `priority/*`, `platform/*`, `area/*`
4. Link to Notion PRD
5. Leave OPEN until deployed

**Creating a task issue:**
1. Use `[Task]` prefix in title
2. Link to parent feature: "Part of #X"
3. Include implementation steps
4. Set labels: `task`, `ready-for-dev`, plus parent's priority/platform
5. Close after PR merged

**Creating a PR:**
1. Branch name: `feature/issue-{number}-{description}`
2. Title: `[Feature] Description (#task-number)`
3. Description with changes, testing checklist, links
4. Link: "Closes #X" and "Part of #Y"
5. Wait for CI, address failures, merge when green

**Closing issues:**
- Task issues: Developer closes after PR merged
- Bug issues: Developer closes after fix verified
- Feature issues: Deployment Agent closes after production deploy
