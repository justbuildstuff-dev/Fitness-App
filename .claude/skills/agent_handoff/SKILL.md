---
name: Agent Handoff Protocol
description: Standardized protocol for agents to hand off work to the next agent in the workflow
---

# Agent Handoff Protocol Skill

This skill defines the standardized protocol for agents to verify work completion, update artifacts, and hand off to the next agent in the automated workflow.

## Workflow Overview

```
User Request
    ↓
BA Agent (Business Analyst)
    ↓
SA Agent (Solutions Architect)
    ↓
Developer Agent
    ↓
Testing Agent
    ↓
QA Agent
    ↓
Deployment Agent
    ↓
Feature Complete
```

## Handoff Mode: AUTOMATED

Agents automatically hand off to the next agent when their work is complete **and approved by the user** (at approval points).

## User Approval Points

User confirmation **required** at these points:

1. **After BA creates requirements** - Before SA starts design
2. **After SA creates design** - Before Developer starts implementation
3. **After QA review** - Before Deployment to production

## Automatic Handoffs (No Approval Needed)

These handoffs happen automatically without user approval:

- **Developer → Testing** (after all PRs merged)
- **Testing → QA** (after tests pass)
- **QA → Developer** (if bugs found, create bug issues and notify)

## Handoff Checklist Template

Before ANY handoff, verify:

- [ ] All deliverables complete
- [ ] Quality checks passed
- [ ] Artifacts updated (GitHub issues, Notion docs)
- [ ] User approval obtained (if required)
- [ ] Next agent has all needed information

## BA Agent → SA Agent Handoff

### Before Handoff Verification

- [ ] User confirmed understanding of requirements
- [ ] PRD complete and clear in Notion
- [ ] User stories created with acceptance criteria (3-7 stories)
- [ ] GitHub feature issue created with all links
- [ ] Bidirectional links work (Notion ↔ GitHub)
- [ ] User approves moving to design phase

### Update Notion

**Change PRD status:** "Requirements Gathering" → "Ready for Design"

**Add status update note:**
```markdown
Requirements complete - [Date]

User confirmed:
- [Key point 1]
- [Key point 2]

Ready for technical design.
```

### Get User Approval

**Ask user:**
```
✅ Requirements documented!

- Notion PRD: [URL]
- GitHub Issue: #XX
- User Stories: [count] stories created

Ready to hand off to Solutions Architect for technical design?
Type 'yes' to proceed or tell me what needs adjustment.
```

### After User Approves, Invoke SA Agent

**Command:** `/sa`

**Message format:**
```
Requirements complete for [Feature Name].

GitHub Issue: #XX
Notion PRD: [URL]

Key considerations:
- [Important point 1]
- [Important point 2]
- [Important point 3]

Please create technical design and break down into implementation tasks.
```

## SA Agent → Developer Agent Handoff

### Before Handoff Verification

- [ ] Technical design complete in Notion
- [ ] Design decisions documented with rationale
- [ ] Implementation tasks created in GitHub (typically 5-10 task issues)
- [ ] Tasks have dependencies identified
- [ ] All tasks linked to parent feature issue
- [ ] User approves design and task breakdown

### Update Notion

**Change Technical Design status:** "In Progress" → "Approved"

**Change PRD status:** "Ready for Design" → "Design Complete"

### Update GitHub

**On parent feature issue:**
- Add comment listing all task issues
- Update labels: Remove `ready-for-design`, Add `design-approved`
- Keep issue OPEN

**Example comment:**
```markdown
✅ Technical design complete

Design document: [Notion URL]

Implementation tasks created:
- #10: Add shared_preferences dependency
- #11: Create ThemeProvider
- #12: Integrate in main.dart
- #13: Create Settings screen
- #14: Wire navigation
- #15: Override Analytics theme
- #16: ThemeProvider tests
- #17: Widget/integration tests

Tasks have dependencies noted. Suggested starting task: #10

Ready for implementation.
```

### Get User Approval

**Ask user:**
```
✅ Technical design complete!

- Design Document: [Notion URL]
- Implementation Tasks: #10-#17 (8 tasks)
- Parent Issue: #XX

Architecture approach:
- [Brief summary of technical approach]
- [Key pattern or decision]

Ready to hand off to Developer Agent for implementation?
Type 'yes' to proceed or tell me what needs adjustment.
```

### After User Approves, Invoke Developer Agent

**Command:** `/developer`

**Message format:**
```
Design approved for [Feature Name].

Start with GitHub Issue: #10
All tasks: #10, #11, #12, #13, #14, #15, #16, #17
Parent feature: #XX

Technical design: [Notion URL]
Detailed design: Docs/Technical_Designs/[Feature]_Technical_Design.md

Key architectural notes:
- [Important pattern to follow]
- [Key dependency or constraint]
- [Suggested starting point]

Please implement tasks sequentially starting with #10.
```

## Developer Agent → Testing Agent Handoff

### Before Handoff Verification

- [ ] All task issues closed
- [ ] All PRs merged to main branch
- [ ] All tests passing on main branch
- [ ] No linter warnings
- [ ] Code follows project patterns
- [ ] Documentation updated (if needed)

### Update GitHub

**On parent feature issue, add comment:**
```markdown
✅ Implementation complete

All tasks finished:
- #10: Add shared_preferences ✓
- #11: Create ThemeProvider ✓
- #12: Integrate in main.dart ✓
- #13: Create Settings screen ✓
- #14: Wire navigation ✓
- #15: Override Analytics theme ✓
- #16: ThemeProvider tests ✓
- #17: Widget/integration tests ✓

PRs merged:
- #XXX, #XXX, #XXX, #XXX, #XXX, #XXX, #XXX, #XXX

All tests passing on main branch.
Ready for automated testing.
```

**Update labels:**
- Remove: `design-approved`
- Add: `ready-for-testing`
- Keep issue OPEN

### Invoke Testing Agent (AUTOMATIC - No User Approval)

**Command:** `/testing`

**Message format:**
```
Implementation complete for [Feature Name].

Parent Issue: #XX
All tasks complete: #10-#17
All PRs merged to main branch

Please run full test suite, check coverage, and create beta build if tests pass.
```

## Testing Agent → QA Agent Handoff

### Before Handoff Verification

- [ ] GitHub Actions workflow completed successfully
- [ ] All tests passed (`all-tests-passed` status check green)
- [ ] Coverage meets requirements (80%+ overall)
- [ ] Security checks passed
- [ ] Beta build created in Firebase App Distribution

### Update GitHub

**On parent feature issue, add comment:**
```markdown
✅ Testing complete

Test Results:
- Unit tests: ✓ All passed
- Widget tests: ✓ All passed
- Integration tests: ✓ All passed
- Coverage: XX% (target: 80%+)
- Security checks: ✓ Passed

Beta build: [Firebase App Distribution link]

Build details:
- Version: [version]
- Build number: [number]
- Commit: [SHA]

Ready for QA review.
```

**Update labels:**
- Remove: `testing`
- Add: `ready-for-qa`
- Keep issue OPEN

### Invoke QA Agent (AUTOMATIC - No User Approval)

**Command:** `/qa`

**Message format:**
```
Testing complete for [Feature Name].

Parent Issue: #XX
All tests passing: ✓
Coverage: XX%
Beta build: [Firebase link]

Please perform QA review against acceptance criteria.
```

## QA Agent → Deployment Agent Handoff

### Before Handoff Verification

- [ ] All acceptance criteria met (from PRD)
- [ ] Manual testing complete on beta build
- [ ] Platform-specific testing done (iOS and/or Android)
- [ ] Accessibility verified
- [ ] Performance acceptable
- [ ] No critical bugs found
- [ ] User approves for production deployment

### Update Notion

**Change PRD status:** "QA" → "Ready for Deployment"

### Update GitHub

**On parent feature issue, add comment:**
```markdown
✅ QA approved

Acceptance Criteria Review:
- [ ] Criterion 1 - ✓ Verified
- [ ] Criterion 2 - ✓ Verified
- [ ] Criterion 3 - ✓ Verified

Manual Testing:
- iOS: ✓ Tested, working as expected
- Android: ✓ Tested, working as expected

Performance:
- Theme switch: <100ms ✓
- Memory usage: Normal ✓

Accessibility:
- Screen reader: ✓ Labels present
- Contrast: ✓ Meets WCAG AA

No critical issues found.
Ready for production deployment.
```

**Update labels:**
- Remove: `ready-for-qa`
- Add: `qa-approved`
- Keep issue OPEN

### Get User Approval

**Ask user:**
```
✅ QA complete!

Feature: [Feature Name]
Parent Issue: #XX

All acceptance criteria met: ✓
Manual testing complete: ✓
Platform testing (iOS/Android): ✓
Performance verified: ✓
Accessibility verified: ✓

No issues found during QA.

Ready to deploy to production?
Type 'yes' to proceed with deployment or 'no' to hold.
```

### After User Approves, Invoke Deployment Agent

**Command:** `/deployment`

**Message format:**
```
QA approved for [Feature Name].

Parent Issue: #XX
All acceptance criteria met: ✓
Manual testing complete: ✓
Beta build tested: [Firebase link]

Ready for production deployment.
```

## QA Agent → Developer Agent (Bug Found)

### When to Use This Handoff

If QA finds bugs during testing, loop back to Developer instead of proceeding to Deployment.

### Create Bug Issues

For each bug found:

**Title:** `[Bug] Description of Bug`

**Use bug template:**
```markdown
## Description
[What's broken]

## Related Feature
Part of #XX (parent feature)

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
- Build: [version from beta]

## Logs/Screenshots
[Error messages, screenshots]
```

**Labels:** `bug`, `priority/[level]`, `platform/[ios|android|both]`

### Update Parent Feature Issue

**Add comment:**
```markdown
⚠️ QA found issues

Bugs created:
- #XX: [Bug description]
- #XX: [Bug description]

Returning to Developer Agent for fixes.
```

**Update labels:**
- Remove: `ready-for-qa`
- Add: `in-development`
- Keep issue OPEN

### Notify Developer

**Direct message to developer (or comment on parent issue):**
```
QA testing found bugs in [Feature Name].

Parent Issue: #XX
Bug issues: #XXX, #XXX

Please fix these bugs and resubmit for testing.
```

**Developer will then:**
1. Fix bugs
2. Create PRs
3. Merge PRs
4. Close bug issues
5. Hand back to Testing Agent

## Deployment Agent → User (Final Handoff)

### After Successful Deployment

**Update GitHub:**

**On parent feature issue:**
```markdown
✅ Deployed to production

Deployment details:
- Version: [version]
- Release date: [date]
- Platforms: [iOS/Android/Both]
- App Store status: [Live/Pending review]
- Play Store status: [Live/Pending review]

Feature now live for all users.
```

**Update labels:**
- Add: `deployed`

**Close issue:** Status = CLOSED

### Update Notion

**Change PRD status:** "Ready for Deployment" → "Deployed"

**Add deployment note with timestamp**

### Notify User

**Message to user:**
```
✅ Feature deployed successfully!

Feature: [Feature Name]
Version: [version]
Deployed: [date]

The feature is now live in production on [platforms].

GitHub Issue #XX closed.
Notion PRD updated to "Deployed" status.

[Any post-deployment notes or monitoring info]
```

## Error Handling in Handoffs

### If Artifact Creation Fails

**Notion fails:**
1. Save content as local markdown
2. Retry once
3. Notify user, continue with GitHub-only
4. Provide markdown for manual Notion entry

**GitHub fails:**
1. Document in Notion
2. Provide formatted text for manual GitHub creation
3. Continue workflow with Notion-only docs

### If Next Agent Not Available

**Manual fallback:**
1. Notify user of handoff attempt
2. Provide all handoff information
3. Ask user to manually invoke next agent when ready

### If Verification Fails

**Example: Tests fail before Testing → QA handoff**

1. DO NOT hand off
2. Create bug issues for failures
3. Update parent issue with status
4. Loop back to Developer Agent
5. Only proceed after issues resolved

## Handoff Communication Style

### Clear and Structured

✅ **Good:**
```
✅ Requirements complete for Dark Mode Support.

GitHub Issue: #47
Notion PRD: https://notion.so/...

Key considerations:
- App uses Material Design 3 - extend existing theme system
- Must work on both iOS and Android
- Analytics screen has custom theming that needs override

Please create technical design and break down into implementation tasks.
```

❌ **Bad:**
```
Requirements done. Check Notion. Ready for design.
```

### Include All Context

- Feature name
- Issue numbers
- Document links
- Key points the next agent needs
- Clear next action

### Professional Tone

- Use checkmarks (✅) for completed phases
- List deliverables with bullet points
- Include metrics/counts
- State next action clearly

## Quick Reference

**Handoff Verbs:**
- BA → SA: "Requirements complete"
- SA → Dev: "Design approved"
- Dev → Testing: "Implementation complete"
- Testing → QA: "Testing complete"
- QA → Deployment: "QA approved"
- Deployment → User: "Deployed to production"

**User Approval Required:**
1. BA → SA (after requirements)
2. SA → Developer (after design)
3. QA → Deployment (before production)

**Automatic Handoffs:**
- Developer → Testing
- Testing → QA
- QA → Developer (if bugs found)

**Always Keep Open Until Deployment:**
- Feature issues stay OPEN
- Only Deployment Agent closes them

**Always Close Immediately:**
- Task issues (Developer closes after merge)
- Bug issues (Developer closes after fix verified)
