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

**Navigation:** See [Docs/README.md](Docs/README.md) for complete documentation navigation guide.

**Documentation System:** See [Docs/Documentation_Lifecycle.md](Docs/Documentation_Lifecycle.md) for:
- When and where each document type is created
- Naming conventions (PascalCase for all documentation)
- Directory structure and organization
- Agent responsibilities for documentation

**Key Documentation Locations:**
- `Docs/Architecture/` - System architecture, data models, security rules, state management
- `Docs/Components/` - Component-specific documentation (Authentication, Firestore, UI components)
- `Docs/Features/` - Feature implementations and screen documentation
- `Docs/Technical_Designs/` - Detailed technical designs for each feature
- `Docs/Testing/` - Testing framework and strategies
- `Docs/Releases/` - Release notes for each version
- `Docs/Process/` - Process documentation and workflow guides
- `Docs/Archive/` - Legacy documentation

**Important Files:**
- [Docs/Architecture/ArchitectureOverview.md](Docs/Architecture/ArchitectureOverview.md) - Review for cross-component changes
- [Docs/Architecture/DataModels.md](Docs/Architecture/DataModels.md) - Firestore schema reference
- [Docs/Testing/TestingFramework.md](Docs/Testing/TestingFramework.md) - Testing patterns and standards
- [Docs/Features/CurrentScreens.md](Docs/Features/CurrentScreens.md) - Screen inventory and pipeline

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

**For Agent-Driven Development:** Follow the Agent Chain workflow (see Agent-Driven Development Workflow section below)

**For Direct Development (non-agent work):**

1. **Review Documentation**:
   - See [Docs/README.md](Docs/README.md) for navigation to relevant documents
   - Review [Docs/Features/CurrentScreens.md](Docs/Features/CurrentScreens.md) for pipeline status
   - Check [Docs/Architecture/ArchitectureOverview.md](Docs/Architecture/ArchitectureOverview.md) for cross-component changes
   - Review relevant component documentation from `Docs/Components/` or `Docs/Architecture/`

2. **Plan & Outline**:
   - State intentions and list sub-tasks before coding
   - Use TodoWrite tool to track complex multi-step tasks

3. **Ask for Confirmation**:
   - Propose plans before implementation

4. **Test-Driven Development**:
   - Review [Docs/Testing/TestingFramework.md](Docs/Testing/TestingFramework.md) before writing tests
   - Review existing tests to understand functionality flows
   - Write new tests aligned with expected outcomes
   - Update existing tests if necessary

5. **Iterative Progress**:
   - Work section by section through the specification

6. **Clear Communication**:
   - Share reasoning and ask for clarification when needed

7. **Update Documentation**:
   - Follow [Docs/Documentation_Lifecycle.md](Docs/Documentation_Lifecycle.md) for naming conventions and structure
   - Update existing documentation in appropriate directories (`Docs/Architecture/`, `Docs/Components/`, `Docs/Features/`)
   - Use PascalCase naming for all new documentation files
   - Documentation is only required when integral functionality has been modified or implemented

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

## Agent Instructions & Skills

**Agent Files:** Each agent has detailed instructions in `.claude/agents/[agent-name].md`
- `ba.md` - Business Analyst Agent
- `sa.md` - Solutions Architect Agent
- `developer.md` - Developer Agent
- `testing.md` - Testing Agent
- `qa.md` - QA Agent
- `deployment.md` - Deployment Agent

**Skills (Reusable Procedural Knowledge):** Located in `.claude/skills/`
- `github_workflow/` - GitHub issues, PRs, labels, workflow management
- `notion_documentation/` - PRD and Technical Design templates
- `flutter_testing/` - Test patterns, coverage requirements, mocking strategies
- `flutter_code_quality/` - Dart style guide, code quality standards
- `agent_handoff/` - Agent-to-agent handoff protocols

Agents automatically reference relevant skills for procedural knowledge. Skills reduce duplication and ensure consistency across all agents.

## Notion Configuration

**Workspace:** FitTrack Development

**Databases:**
- **Product Requirements** - Feature PRDs and specifications (created by BA Agent)
- **User Stories** - User stories linked to PRDs (stored within PRD, not separate database)
- **Technical Designs** - Architecture and design documents (summary created by SA Agent)
- **Decisions & Notes** - Meeting notes and key decisions

**Templates:**
- Feature PRD Template - For new feature requirements (see `.claude/skills/notion_documentation/`)
- Technical Design Template - For technical architecture (see `.claude/skills/notion_documentation/`)

**Hybrid Documentation Approach:**
- **Notion:** Metadata, tracking, summaries, links (better for searchability and properties)
- **Git (Docs/):** Detailed technical content, version-controlled documentation
- **Example:** SA creates summary in Notion + detailed design in `Docs/Technical_Designs/[Feature_Name]_Technical_Design.md`

**Workflow:**
1. BA creates PRD in "Product Requirements" database
2. BA creates user stories within the PRD (not as separate database entries)
3. SA creates technical design summary in "Technical Designs" database
4. SA creates detailed design in `Docs/Technical_Designs/` (version-controlled)
5. All documents link bidirectionally (Notion ↔ GitHub)

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

**Each agent has complete instructions in `.claude/agents/[agent-name].md`**

**Quick Reference:**

**BA Agent** - Requirements gathering
- Interview users to understand needs
- Create PRD in Notion (see `.claude/skills/notion_documentation/`)
- Create GitHub feature issue (see `.claude/skills/github_workflow/`)
- Documentation: PRD (Notion), Feature Issue (GitHub)
- Hand off to SA after user approval

**SA Agent** - Technical design
- Analyze codebase and discover existing patterns
- Create technical design summary (Notion) + detailed design (`Docs/Technical_Designs/`)
- Break down into implementation tasks (GitHub issues)
- Documentation: Technical Design (Notion + Git), Task Issues (GitHub), Architecture/Component docs as needed
- Hand off to Developer after user approval

**Developer Agent** - Implementation
- Implement one task at a time in feature branches
- Write tests for all code (see `.claude/skills/flutter_testing/`)
- Follow code quality standards (see `.claude/skills/flutter_code_quality/`)
- Create PRs that trigger GitHub Actions
- Documentation: Implementation Notes (added to Technical Design), Code comments
- Hand off to Testing after all PRs merged

**Testing Agent** - Automated testing
- Verify PR tests passed (tests run on PRs, not main branch)
- Check coverage meets requirements (80%+ overall)
- Create beta build via `create-beta-build` label
- Documentation: Test reports (GitHub comments)
- Hand off to QA if tests pass, or back to Developer if bugs found

**QA Agent** - Manual quality assurance
- Test beta build on actual devices
- Validate all acceptance criteria from PRD
- Test edge cases and user experience
- Documentation: QA reports (GitHub comments)
- Hand off to Deployment if approved, or back to Developer if critical bugs found

**Deployment Agent** - Production release
- Prepare release artifacts (version bump, changelog, release notes)
- Guide manual store submission (provide checklist)
- Close feature issue after deployment confirmed
- Documentation: Release Notes (`Docs/Releases/`), CHANGELOG, GitHub Release
- Final agent - completes feature lifecycle

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

## Documentation System

**See [Docs/Documentation_Lifecycle.md](Docs/Documentation_Lifecycle.md) for complete documentation system.**

### Document Types

1. **Product Requirements Document (PRD)** - Created by BA Agent in Notion
2. **Technical Design Document** - Created by SA Agent (summary in Notion + detailed in `Docs/Technical_Designs/`)
3. **Architectural/Framework Documents** - Created by SA Agent in `Docs/Architecture/` or `Docs/Components/`
4. **Testing Framework** - Located in `Docs/Testing/`
5. **Implementation Notes** - Added by Developer Agent to Technical Design documents
6. **Release Documentation** - Created by Deployment Agent in `Docs/Releases/`
7. **Process Documentation** - Located in `Docs/Process/`

### Naming Conventions

**All documentation uses PascalCase:**
- Architecture: `ArchitectureOverview.md`, `DataModels.md`, `StateManagement.md`
- Components: `Authentication.md`, `FirestoreService.md`, `UIComponents.md`
- Features: `AnalyticsScreen.md`, `CurrentScreens.md`
- Technical Designs: `[Feature_Name]_Technical_Design.md` (with underscores)
- Release Notes: `release_notes_v[X.Y.Z].md` (lowercase v, semver format)

### Directory Structure

```
Docs/
├── README.md                    # Navigation guide
├── Documentation_Lifecycle.md   # Documentation system master document
├── Architecture/                # System architecture and patterns
├── Components/                  # Component-specific documentation
├── Features/                    # Feature implementations
├── Technical_Designs/           # Detailed technical designs
├── Testing/                     # Testing framework and strategies
├── Releases/                    # Release notes for each version
├── Process/                     # Process documentation and guides
└── Archive/                     # Legacy documentation
```

### Agent Documentation Responsibilities

- **BA:** PRD (Notion), GitHub Feature Issue
- **SA:** Technical Design (Notion + Git), Task Issues, Architecture/Component docs
- **Developer:** Implementation Notes, Code comments
- **Testing:** Test reports (GitHub comments)
- **QA:** QA reports (GitHub comments)
- **Deployment:** Release Notes, CHANGELOG, GitHub Release

### Skills System

The `.claude/skills/` directory contains reusable procedural knowledge that agents automatically reference:

- **GitHub Workflow** - Issue templates, PR standards, labels
- **Notion Documentation** - PRD and Technical Design templates
- **Flutter Testing** - Test patterns, coverage requirements
- **Flutter Code Quality** - Dart style guide, best practices
- **Agent Handoff** - Handoff protocols between agents

Skills reduce duplication across agent files and ensure consistency.