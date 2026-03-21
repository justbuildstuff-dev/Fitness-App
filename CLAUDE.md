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
- `Docs/PRDs/` - Product Requirements Documents for each feature
- `Docs/Technical_Designs/` - Detailed technical designs for each feature
- `Docs/Testing/` - Testing framework, strategies, and CI guides
- `Docs/Releases/` - Release notes for each version
- `Docs/Archive/` - Legacy and deprecated documentation

**Important Files:**
- [Docs/Architecture/ArchitectureOverview.md](Docs/Architecture/ArchitectureOverview.md) - Review for cross-component changes
- [Docs/Architecture/DataModels.md](Docs/Architecture/DataModels.md) - Firestore schema reference
- [Docs/Testing/TestingFramework.md](Docs/Testing/TestingFramework.md) - Testing patterns and standards
- [Docs/CurrentScreens.md](Docs/CurrentScreens.md) - Screen inventory and pipeline

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

### Repository Security

**CRITICAL: This repository is PUBLIC.**

Before committing ANY code:
1. **Verify no API tokens** - See `.claude/skills/github_workflow/SKILL.md` security checklist
2. **Check .gitignore** - Sensitive files must be ignored
3. **Use templates** - Never commit `.env` or `settings.json` with real values
4. **Scan commits** - Run security verification commands before push

**Protected files** (in `.gitignore`, never commit):
- `.claude/settings.json` - Contains GitHub tokens
- `.env*` files with real values
- Private keys (`.pem`, `.key`, `.p12`)
- Keystores (`.jks`, `.keystore`)
- Any file with API tokens or credentials

**Safe to commit:**
- Firebase client API keys (protected by Firestore rules)
- Template files (`.template`, `.example`)
- Test fixtures with fake credentials
- Documentation

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
   - Review [Docs/CurrentScreens.md](Docs/CurrentScreens.md) for pipeline status
   - Check [Docs/Architecture/ArchitectureOverview.md](Docs/Architecture/ArchitectureOverview.md) for cross-component changes
   - Review relevant documentation from `Docs/Architecture/` or `Docs/Technical_Designs/`

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
   - Update existing documentation in appropriate directories (`Docs/Architecture/`, `Docs/Technical_Designs/`)
   - Use PascalCase naming for all new documentation files
   - Documentation is only required when integral functionality has been modified or implemented

## Firebase Configuration

Deploy the provided security rules and indexes:
- `firebase deploy --only firestore:rules`
- `firebase deploy --only firestore:indexes`

## Testing Requirements

**Test Types:**
- **Unit tests** - For all models, providers, and business logic (90%+ coverage)
- **Widget tests** - For screens and complex UI components
- **Integration tests** - For service layer with REAL Firebase operations (REQUIRED for service changes)
- **E2E tests** - For critical user flows (create program, duplicate week, offline sync)

**CRITICAL: Integration Test Requirement**

**When modifying `lib/services/*.dart`:**
1. ✅ **REQUIRED:** Create corresponding `test/services/*_integration_test.dart`
2. ✅ Use template: `fittrack/test/services/INTEGRATION_TEST_TEMPLATE.dart`
3. ✅ Use helper: `FirebaseIntegrationTestHelper` from `test/helpers/`
4. ✅ Tests MUST connect to Firebase emulators (localhost:8080, localhost:9099)
5. ✅ Tests MUST create real data in Firestore
6. ✅ Tests MUST validate actual Firebase operations (NOT mocks)

**Why:** Service-level integration tests prevent false passes by validating real Firebase behavior. CI will enforce this requirement.

**Reference:** See `Docs/Testing/TestClassification.md` for complete test classification guide

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
Security Audit Agent
↓
Accessibility Audit Agent
↓
QA Agent
↓
App Store Prep Agent
↓
Deployment Agent
↓
Feature Complete

### User Approval Points

User confirmation required at these points:
1. **After BA creates requirements** - Before SA starts design
2. **After SA creates design** - Before Developer starts implementation
3. **After QA review** - Before App Store Prep begins
4. **After App Store Prep** - Before Deployment to production

### No Approval Needed (Automatic)

These handoffs happen automatically:
- Developer → Testing (after all PRs merged)
- Testing → Security Audit (after tests pass)
- Security Audit → Accessibility Audit (after security approved)
- Accessibility Audit → QA (after audit passed)
- QA → Developer (if bugs found)
- Security Audit → Developer (if critical/high issues found)
- Accessibility Audit → Developer (if blocking issues found)

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
`@security-audit` - Security Audit Agent (OWASP, Firestore rules, CVE, PII)
`@accessibility` - Accessibility Audit Agent (WCAG AA, screen reader, contrast)
`@qa` - QA Agent (manual quality assurance)
`@appstore-prep` - App Store Prep Agent (listing copy, privacy policy, screenshots)
`@deployment` - Deployment Agent (production release)

## Agent Instructions & Skills

**Agent Files:** Each agent has detailed instructions in `.claude/agents/[agent-name].md`
- `ba.md` - Business Analyst Agent
- `sa.md` - Solutions Architect Agent
- `developer.md` - Developer Agent
- `testing.md` - Testing Agent
- `security-audit.md` - Security Audit Agent
- `accessibility-audit.md` - Accessibility Audit Agent
- `qa.md` - QA Agent
- `appstore-prep.md` - App Store Prep Agent
- `deployment.md` - Deployment Agent

**Skills (Reusable Procedural Knowledge):** Located in `.claude/skills/`
- `github_workflow/` - GitHub issues, PRs, labels, workflow management
- `flutter_testing/` - Test patterns, coverage requirements, mocking strategies
- `flutter_code_quality/` - Dart style guide, code quality standards
- `agent_handoff/` - Agent-to-agent handoff protocols

Agents automatically reference relevant skills for procedural knowledge. Skills reduce duplication and ensure consistency across all agents.

## Documentation Workflow

All documentation is stored in the Git repository under `Docs/`. Status tracking is done via GitHub issue labels.

**Workflow:**
1. BA creates PRD in `Docs/PRDs/[Feature_Name]_PRD.md`
2. BA creates/updates Feature Issue in GitHub with PRD link
3. SA creates detailed Technical Design in `Docs/Technical_Designs/[Feature_Name]_Technical_Design.md`
4. SA creates Task Issues in GitHub linked to parent feature issue
5. All documents link to GitHub issues; status tracked via issue labels

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
`ready-for-security` - Tests passed, awaiting security audit
`security-approved` - Security audit passed
`security-issues` - Security audit found blocking issues
`ready-for-accessibility` - Security done, awaiting accessibility audit
`accessibility-approved` - Accessibility audit passed
`accessibility-issues` - Accessibility audit found blocking issues
`ready-for-qa` - Accessibility done, ready for QA
`qa-approved` - QA passed, ready for store prep
`ready-for-store-prep` - QA approved, awaiting store asset prep
`store-assets-ready` - App Store prep complete, awaiting deployment
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
- Runs on: PRs to main, feature/**, bug/** branches
- Jobs: unit tests, widget tests, integration tests, performance tests, security checks
- Status check: all-tests-passed - Single check agents query for pass/fail

## Git Branching Strategy

**Hierarchical Branching: Task → Feature/Bug → Main**

The project uses a structured branching strategy for better CI efficiency and safer integration testing:

**Feature Parent Branches** (created by SA Agent):
- `feature/issue-{number}-{short-description}`
- Example: `feature/issue-49-delete-functionality`
- Created when design is approved
- Base for all task branches
- Merges to `main` after all tasks complete

**Bug Parent Branches** (created by SA Agent or Developer):
- `bug/issue-{number}-{short-description}`
- Example: `bug/issue-123-integration-test-infrastructure`
- Created for bug fixes requiring multiple tasks
- Merges to `main` after all tasks complete

**Task Branches** (created by Developer Agent):
- `task/{task-number}-{short-description}`
- Example: `task/54-cascade-count-model`
- Branched from parent feature/bug branch (NOT main)
- Merges to parent feature/bug branch via PR
- One task per branch

**Workflow:**
```
main
 └── feature/issue-49-delete-functionality
      ├── task/54-cascade-count-model → PR to feature branch
      ├── task/55-firestore-counts → PR to feature branch
      └── task/56-provider-method → PR to feature branch

      → Final PR: feature branch → main (after all tasks merged)
```

**Benefits:**
- Reduces CI runs by 43% (tests complete feature before main)
- Main branch only sees complete, tested features
- Task-level history preserved
- Safer rollback (revert feature or cherry-pick tasks)

**Merge Strategy:**
- Task PRs: Squash and merge to feature/bug branch
- Feature/Bug PRs: Do NOT squash (preserve task commits)

## Agent Communication Protocol
**BA Agent hands off to SA:**
```bash
@sa "Requirements complete for [Feature Name].

GitHub Issue: #XX
PRD: Docs/PRDs/[Feature_Name]_PRD.md

Key considerations:
- [Point 1]
- [Point 2]

Please create technical design and implementation tasks."
```
**SA Agent hands off to Developer:**
```bash
@developer "Design approved for [Feature Name].

Parent Issue: #XX
Feature Branch: feature/issue-XX-feature-name (created)
Implementation Tasks: #XX, #XX, #XX

Technical Design: Docs/Technical_Designs/[Feature_Name]_Technical_Design.md

IMPORTANT: Create task branches from the feature branch, not main.
Target all PRs to the feature branch."
```
**Developer Agent hands off to Testing:**
```bash
@testing "Implementation complete for [Feature Name].

Parent Issue: #XX
Feature Branch: feature/issue-XX-feature-name
All tasks complete: #XX-#XX (all merged to feature branch)

Final PR to main: #XXX (created, DO NOT merge yet)

Please verify all tests pass on the feature→main PR and approve merge if tests pass."
```
**Testing Agent hands off to Security Audit:**
```bash
@security-audit "Testing complete for [Feature Name].

Parent Issue: #XX
All tests passing: ✓
Beta build: [Firebase link]

Please perform security audit before QA begins."
```
**Security Audit Agent hands off to Accessibility Audit:**
```bash
@accessibility "Security audit complete for [Feature Name].

Parent Issue: #XX
Security audit: PASSED ✓
Issues found: [None / n medium/low items logged to backlog]

Please perform accessibility audit."
```
**Accessibility Audit Agent hands off to QA:**
```bash
@qa "Accessibility audit complete for [Feature Name].

Parent Issue: #XX
Security audit: PASSED ✓
Accessibility audit: PASSED ✓
Beta build: [Firebase link]

Ready for manual QA and acceptance testing."
```
**QA Agent hands off to App Store Prep:**
```bash
@appstore-prep "QA approved for [Feature Name].

Parent Issue: #XX
All acceptance criteria met: ✓
Manual testing complete: ✓
Version: [X.Y.Z]

Please prepare App Store and Play Store submission assets."
```
**App Store Prep Agent hands off to Deployment:**
```bash
@deployment "Store assets ready for [Feature Name].

Parent Issue: #XX
App Store assets: READY ✓
Privacy policy: Updated ✓
Screenshots spec: READY ✓
Version: [X.Y.Z]

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
7. `ready-for-security` (Tests passed)
8. `security-approved` (Security audit passed)
9. `ready-for-accessibility` (Security done)
10. `accessibility-approved` (Accessibility audit passed)
11. `ready-for-qa` (Accessibility done)
12. `qa-approved` (QA verified)
13. `ready-for-store-prep` (QA approved, user approved)
14. `store-assets-ready` (Store assets complete)
15. `ready-for-deploy` (User approved for production)
16. `deployed` (Live in production, issue CLOSED)

## When Working with Agents

**Each agent has complete instructions in `.claude/agents/[agent-name].md`**

**Quick Reference:**

**BA Agent** - Requirements gathering
- Interview users to understand needs
- Create PRD in `Docs/PRDs/` (see `.claude/skills/github_workflow/`)
- Create GitHub feature issue
- Documentation: PRD (`Docs/PRDs/`), Feature Issue (GitHub)
- Hand off to SA after user approval

**SA Agent** - Technical design
- Analyze codebase and discover existing patterns
- Create detailed Technical Design in `Docs/Technical_Designs/`
- Break down into implementation tasks (GitHub issues)
- Documentation: Technical Design (`Docs/Technical_Designs/`), Task Issues (GitHub), Architecture docs as needed
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
- Hand off to Security Audit if tests pass, or back to Developer if bugs found

**Security Audit Agent** - Code security review
- OWASP Mobile Top 10 audit against Flutter/Firebase stack
- Firestore rules review, hardcoded secrets scan, dependency CVE check
- PII audit — catalog what user data is stored
- Detailed report: `Docs/SecurityReports/` (gitignored — never committed)
- GitHub comment: summary only (repo is public — no exploit details)
- Hand off to Accessibility Audit if passed, or back to Developer if critical/high issues

**Accessibility Audit Agent** - UI accessibility review
- WCAG AA compliance: semantic labels, color contrast, touch targets
- Dynamic text scaling, screen reader focus order, reduced motion
- Documentation: Accessibility report (GitHub issue comment)
- Hand off to QA if passed, or back to Developer if blocking issues found

**QA Agent** - Manual quality assurance
- Receives from Accessibility Audit Agent
- Test beta build on actual devices
- Validate all acceptance criteria from PRD
- Test edge cases and user experience
- Documentation: QA reports (GitHub comments)
- Hand off to App Store Prep (after user approval), or back to Developer if critical bugs found

**App Store Prep Agent** - Store submission preparation
- Draft App Store and Play Store listing copy
- Draft privacy policy skeleton
- Age rating questionnaire, screenshot specifications, compliance checklist
- Documentation: All assets in `Docs/StoreAssets/` (committed — public-facing content)
- Hand off to Deployment after user approval

**Deployment Agent** - Production release
- Receives from App Store Prep Agent (after user approval)
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

1. **Product Requirements Document (PRD)** - Created by BA Agent in `Docs/PRDs/`
2. **Technical Design Document** - Created by SA Agent in `Docs/Technical_Designs/`
3. **Architectural Documents** - Created by SA Agent in `Docs/Architecture/`
4. **Testing Framework** - Located in `Docs/Testing/`
5. **Implementation Notes** - Added by Developer Agent to Technical Design documents
6. **Release Documentation** - Created by Deployment Agent in `Docs/Releases/`

### Naming Conventions

**All documentation uses PascalCase:**
- Architecture: `ArchitectureOverview.md`, `DataModels.md`, `StateManagement.md`
- PRDs: `[Feature_Name]_PRD.md` (with underscores)
- Technical Designs: `[Feature_Name]_Technical_Design.md` (with underscores)
- Release Notes: `release_notes_v[X.Y.Z].md` (lowercase v, semver format)

### Directory Structure

```
Docs/
├── README.md                    # Navigation guide
├── Documentation_Lifecycle.md   # Documentation system master document
├── CurrentScreens.md            # Screen inventory and pipeline
├── Architecture/                # System architecture and patterns
├── PRDs/                        # Product Requirements Documents
├── Technical_Designs/           # Detailed technical designs
├── Testing/                     # Testing framework, strategies, CI guides
├── Releases/                    # Release notes for each version
└── Archive/                     # Legacy and deprecated documentation
```

### Agent Documentation Responsibilities

- **BA:** PRD (`Docs/PRDs/`), GitHub Feature Issue
- **SA:** Technical Design (`Docs/Technical_Designs/`), Task Issues, Architecture docs
- **Developer:** Implementation Notes, Code comments
- **Testing:** Test reports (GitHub comments)
- **QA:** QA reports (GitHub comments)
- **Deployment:** Release Notes, CHANGELOG, GitHub Release

### Skills System

The `.claude/skills/` directory contains reusable procedural knowledge that agents automatically reference:

- **GitHub Workflow** - Issue templates, PR standards, labels
- **Flutter Testing** - Test patterns, coverage requirements
- **Flutter Code Quality** - Dart style guide, best practices
- **Agent Handoff** - Handoff protocols between agents

Skills reduce duplication across agent files and ensure consistency.