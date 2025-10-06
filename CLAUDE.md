# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

**FitTrack** is a mobile-first workout tracking app built on Firebase with the following architecture:

- **Client**: Flutter (iOS + Android) 
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Data Structure**: Hierarchical Firestore collections under `users/{userId}/programs/{programId}/weeks/{weekId}/workouts/{workoutId}/exercises/{exerciseId}/sets/{setId}`

## Key Files & Components

### Configuration Files
- `fittrack/firestore.rules` - Complete security rules with per-user data scoping and admin support
- `fittrack/firestore.indexes.json` - Firestore composite indexes for efficient queries

### Documentation
- `Docs/Workout_Tracker_Final_Spec.md` - Complete technical specification with data models, security rules, and implementation details
- `Docs/original_README.md` - Collaboration guidelines for working with Claude Code
- `Docs/*` - Includes all documentation for the project and should be reviewed when getting context for the current task. Documents exist for each component of the application and there is also and architectural overview. You should ask for the necessary document to be added for context when implementing changes. The Architectural Overview should be requested when adding new functionality or cross-component updates to make sure the updates align with the vision for the application.

## Data Model

The app uses a strict hierarchical structure:
```
users/{userId}/
  programs/{programId}/
    weeks/{weekId}/
      workouts/{workoutId}/
        exercises/{exerciseId}/
          sets/{setId}
```

Every document includes a `userId` field for security and efficient querying.

## Security & Authorization

- **Authentication**: Firebase Auth with per-user data scoping
- **Authorization**: Firestore rules enforce `request.auth.uid == userId` 
- **Admin Role**: Custom claims with `admin: true` for support operations
- **Validation**: Server-side validation for all document fields and types

## Key Implementation Patterns

### Exercise Types & Set Fields
- `strength` → `reps` (required), `weight` (optional), `restTime`
- `cardio`/`time-based` → `duration` (required), `distance` (optional)  
- `bodyweight` → `reps` (required)
- `custom` → flexible user-configured fields

### Duplication Strategy
- Client-side implementation with batched writes (≤450 ops/batch)
- Selective field copying based on `exerciseType`
- Deep copying: Week → Workouts → Exercises → Sets
- Reset `checked` to false, optionally reset `weight` to null for fresh tracking

### Development Workflow
- This plan should be followed (in order) whenever a new feature, feature update, or bug fix is requested.
- CurrentScreens.md should be reviewed at the start of each session to see what is still in the pipeline to be completed.

1. **Review Documentation**: 
  - Check the document titles in the @Docs folder.
  - Request access to document titles that sound relevant.
  - State why the document would help with development.
2. **Plan & Outline**: 
  - State intentions and list sub-tasks before coding.
3. **Ask for Confirmation**:
  - Propose plans before implementation.
4. **Test-Driven Development**:
  - TestingFramework.md should be reviewed before writing tests.
  - Review existing tests to help with understanding functionality flows.
  - write new tests aligned defined by the expected outcomes of the new functionality.
  - Update existing tests if necessary.
5. **Iterative Progress**: 
  - Work section by section through the specification.
6. **Clear Communication**:
  - Share reasoning and ask for clarification when needed.
7. **Update Documentation**:
  - Existing documentation files within the @Docs folder should be updated to align with any changes that were made.
  - If the updates do not fit entirely within an already existing document:
    - Create a new document in @Docs for the new functionality
    - Follow the exact same formatting, tone, and level of detail as other, already existing documents.
    - Documentation is only required when an integral piece of functionality has been modified or implemented. Documentation does not need to be created as a summary of everything that has been done in that session.

## Firebase Configuration

Deploy the provided security rules and indexes:
- `firebase deploy --only firestore:rules`
- `firebase deploy --only firestore:indexes`

## Testing Requirements

- Unit tests for duplication logic and validation
- Integration tests with Firebase Emulator (Auth + Firestore)
- E2E tests for core flows (create program, duplicate week, offline sync)

## Commands
- When asked to deploy the application for testing, a check should be done to see if the emulators are already running before redeploying. If the emulators are already running and accessible then a hot redeploy of the application should be performed. 

## Agent-Driven Development Workflow

This project uses an **automated agent workflow** for feature development. Agents handle requirements gathering, design, implementation, testing, QA, and deployment.

### Agent Workflow Mode: AUTOMATED

Agents automatically hand off to the next agent when their work is complete and approved by the user.

### Agent Chain
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

### User Approval Points

User confirmation required at these points:
1. **After BA creates requirements** - Before SA starts design
2. **After SA creates design** - Before Developer starts implementation
3. **After QA review** - Before Deployment to production

### No Approval Needed (Automatic)

These handoffs happen automatically:
- Developer → Testing (after all PRs merged)
- Testing → QA (after tests pass)
- QA → Developer (if bugs found)

### Invoking Agents

Agents are invoked using:
```bash

  claude chat @agent-name

```
Available agents:

`@ba` - Business Analyst (requirements gathering)
`@sa` - Solutions Architect (technical design)
`@developer` - Flutter Developer (implementation)
`@testing` - Testing Agent (automated tests)
`@qa` - QA Agent (quality assurance)
`@deployment` - Deployment Agent (production release)

## Agent Instructions
Each agent has detailed instructions in .claude/agents/[agent-name].md

## Notion Configuration
**Workspace:** FitTrack Development
**Databases:**

- **Product Requirements** - Feature PRDs and specifications
- **User Stories** - User stories linked to PRDs
- **Technical Designs** - Architecture and design documents
- **Decisions & Notes** - Meeting notes and key decisions

**Templates:**

- Feature PRD Template - For new feature requirements
- Technical Design Template - For technical architecture

**Workflow:**

1. BA creates PRD in "Product Requirements"
2. BA creates user stories in "User Stories" linked to PRD
3. SA creates technical design in "Technical Designs" linked to PRD
4. All documents link back to GitHub issues

## GitHub Configuration
**Repository:** justbuildstuff-dev/Fitness-App

**Issue Labels:**
*Workflow States:*

`requirements-complete` - BA finished, ready for SA
`ready-for-design` - Requirements approved
`design-approved` - Design approved, ready for dev
`ready-for-dev` - Tasks ready for implementation
`in-development` - Currently being coded
`in-review` - PR open, awaiting review
`ready-for-testing` - Code merged, ready for tests
`testing` - Tests running
`ready-for-qa` - Tests passed, ready for QA
`qa-approved` - QA passed, ready for deployment
`ready-for-deploy` - Approved for production
`deployed` - Live in production

*Issue Types:*

`feature` - New feature
`task` - Implementation task
`bug` - Bug report
`epic` - Large feature spanning multiple issues

*Priority:*

`priority/critical`
`priority/high`
`priority/medium`
`priority/low`

*Platform:*

`platform/ios`
`platform/android`
`platform/both`

*Area:*

`area/auth`
`area/ui`
`area/api`
`area/database`
`area/notifications`

*Issue Templates:*

`feature.md` - Feature requests
`task.md` - Implementation tasks
`bug.md` - Bug reports

## GitHub Actions:

- Workflow: fittrack_test_suite.yml
- Runs on: PRs and pushes to main/develop
- Jobs: unit tests, widget tests, integration tests, performance tests, security checks
- Status check: all-tests-passed - Single check agents query for pass/fail

## Agent Communication Protocol
**BA Agent hands off to SA:**
```bash
@sa "Requirements complete for [Feature Name].

GitHub Issue: #XX
Notion PRD: [URL]

Key considerations:
- [Point 1]
- [Point 2]

Please create technical design and implementation tasks."
```
**SA Agent hands off to Developer:**
```bash
@developer "Design approved for [Feature Name].

Start with GitHub Issue: #XX
All tasks: #XX, #XX, #XX

Technical design: [Notion URL]"
```
**Developer Agent hands off to Testing:**
```bash
@testing "All implementation complete for [Feature Name].

Parent Issue: #XX
PRs merged: #XXX, #XXX, #XXX

Please run full test suite and create beta build."
```
**Testing Agent hands off to QA:**
```bash
@qa "Testing complete for [Feature Name].

Parent Issue: #XX
All tests passing: ✓
Beta build: [Firebase link]

Ready for QA review."
```
**QA Agent hands off to Deployment:**
```bash
@deployment "QA approved for [Feature Name].

Parent Issue: #XX
All acceptance criteria met: ✓
Manual testing complete: ✓

Ready for production deployment."
```
### Issue Lifecycle & Ownership

**Feature Issues** (created by BA Agent):
- Format: `[Feature] Feature Name`
- Remains **OPEN** throughout entire development workflow
- Tracks overall feature progress from requirements to deployment
- Updated by SA Agent with implementation task links
- Labels updated as workflow progresses through stages
- **Closed by:** Deployment Agent after successful production deployment
- **Never closed by:** BA, SA, Developer, or Testing agents

**Task Issues** (created by SA Agent):
- Format: `[Task] Specific Implementation Task`
- Child issues of parent feature issue
- Each represents independently implementable, testable work
- **Closed by:** Developer Agent immediately after PR merged and tests pass
- Typically 5-10 task issues per feature

**Bug Issues** (created by Testing or QA Agent):
- Format: `[Bug] Description of Bug`
- Created when automated tests or QA testing finds problems
- Linked to parent feature issue
- **Closed by:** Developer Agent after bug fix merged and verified

**Example Workflow:**
Issue #47: [Feature] Dark Mode Support
Status: OPEN (created by BA)
└─ Issue #48: [Task] Create Theme Service
Status: CLOSED (completed by Developer)
└─ Issue #49: [Task] Add Settings Toggle
Status: CLOSED (completed by Developer)
└─ Issue #50: [Task] Apply Themes
Status: CLOSED (completed by Developer)
└─ Issue #51: [Bug] Theme flicker on startup
Status: CLOSED (fixed by Developer)
Final: Issue #47 CLOSED by Deployment Agent after production release

**Label Progression for Feature Issues:**
1. `requirements-complete` (BA finished)
2. `design-approved` (SA finished, user approved)
3. `in-development` (Developer working)
4. `in-review` (PRs open)
5. `ready-for-testing` (All PRs merged)
6. `testing` (Testing Agent running tests)
7. `ready-for-qa` (Tests passed)
8. `qa-approved` (QA verified)
9. `ready-for-deploy` (Approved for production)
10. `deployed` (Live in production, issue CLOSED)

## When Working with Agents
**If you're the BA Agent:**

- Start conversations with requirement questions
- Create Notion PRDs using "Feature PRD Template"
- Create GitHub issues using "Feature Request" template
- Get user approval before handing off to SA

**If you're the SA Agent:**

- Read requirements from Notion PRD and GitHub issue
- Create technical design in Notion using "Technical Design Template"
- Break down into implementation tasks in GitHub
- Get user approval before handing off to Developer

**If you're the Developer Agent:**

- Read GitHub tasks and linked Notion designs
- Implement in feature branches
- Create PRs that trigger GitHub Actions
- Update task status as you progress

**If you're the Testing Agent:**

- Check GitHub Actions results via GitHub MCP
- Read test logs and coverage reports
- Create Firebase beta builds
- Create bug issues if tests fail

**If you're the QA Agent:**

- Verify against Notion PRD acceptance criteria
- Check GitHub Actions all passed
- Review security scans
- Approve for deployment or create bug issues

**If you're the Deployment Agent:**

- Verify all GitHub checks passed
- Create release tags
- Deploy to App Store/Play Store
- Close all related issues
- Update Notion documentation

## Extended Thinking Mode
For complex problems, use these keywords to trigger extended reasoning:

- `"think"` - Basic extended thinking
- `"think hard"` - More reasoning time
- `"think harder"` - Even more reasoning time
- `"ultrathink"` - Maximum reasoning budget

Use extended thinking for:

- Complex architectural decisions
- Multi-platform features with different UX
- Security-critical implementations
- Performance optimization strategies
- Large refactoring decisions


**Remember:** This is an agent-driven workflow. Each agent should complete its work, verify quality, get user approval when required, then hand off to the next agent. The goal is automation with quality checkpoints.