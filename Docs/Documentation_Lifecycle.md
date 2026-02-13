# Documentation Lifecycle

This document defines what documentation exists in the FitTrack project, who creates it, when it's created, where it lives, and how it's maintained.

## Table of Contents

1. [Documentation Types](#documentation-types)
2. [Naming Conventions](#naming-conventions)
3. [Directory Structure](#directory-structure)
4. [Creation Workflow](#creation-workflow)
5. [Update Guidelines](#update-guidelines)

---

## Documentation Types

### 1. Product Requirements Document (PRD)

**Purpose:** Define business requirements, user stories, and acceptance criteria
**Created by:** BA Agent
**When:** After requirements gathering (BA Phase 2)
**Location:** `Docs/PRDs/[Feature_Name]_PRD.md`

**Contents:**
- Business problem statement
- User stories (3-7) with acceptance criteria
- Functional requirements
- Non-functional requirements (performance, security, accessibility)
- Success metrics
- Edge cases and error handling

**Lifecycle:**
- Created: After user confirms requirements
- Updated: Rarely (requirements should be stable before design)
- Status tracked via GitHub issue labels

**Linked to:**
- GitHub Feature Issue (bidirectional link)
- Technical Design (from Technical Design to PRD)

---

### 2. Technical Design Document

**Purpose:** Define technical architecture, component design, and implementation approach
**Created by:** SA Agent
**When:** After PRD approved, before implementation (SA Phase 2)
**Location:** `Docs/Technical_Designs/[Feature_Name]_Technical_Design.md`

**Naming Convention:** `[Feature_Name]_Technical_Design.md`
- Use PascalCase for multi-word features
- Example: `Dark_Mode_Technical_Design.md`
- Example: `Exercise_Library_Technical_Design.md`

**Contents:**
- Current architecture analysis (discovered patterns)
- Architecture overview with rationale
- Component design (new and modified)
- Implementation tasks breakdown (5-10 tasks)
- Testing strategy
- Technical decisions with justification
- Security, performance, accessibility considerations
- Risks and mitigations

**Lifecycle:**
- Created: After reading PRD, during SA Phase 2
- Updated:
  - By SA if design changes before implementation
  - By Developer in "Implementation Notes" section (as-built)

**Linked to:**
- PRD (parent requirement)
- GitHub Feature Issue
- GitHub Task Issues (child tasks)

---

### 3. Architectural Documents

**Purpose:** Document enduring architectural patterns, frameworks, and system design
**Created by:** SA Agent (initially), any agent (when discovering patterns)
**When:**
- Initial project setup
- When introducing new architectural patterns
- When documenting discovered patterns for reuse

**Location:** `Docs/Architecture/`

**Naming Convention:** `[Topic].md` (PascalCase)

**Examples:**
- `ArchitectureOverview.md` - Overall system architecture
- `DataModels.md` - Database schema and Firestore structure
- `SecurityRules.md` - Firebase security rules implementation
- `StateManagement.md` - State management patterns (Provider)

**Contents:**
- Architecture decisions
- Patterns and conventions
- Code organization
- Integration points
- Examples and usage

**Lifecycle:**
- Created: When pattern/framework is introduced
- Updated: When patterns evolve or expand
- Living documents (continuously maintained)

---

### 4. Testing Framework Documentation

**Purpose:** Define testing strategy, patterns, and standards
**Created by:** SA Agent (initially), Developer Agent (as patterns emerge)
**When:** Initial project setup, updated as testing patterns mature
**Location:** `Docs/Testing/`

**Contents:**
- Testing philosophy (TDD approach)
- Test types (unit, widget, integration)
- Testing patterns and examples
- Mocking strategies
- Coverage requirements
- CI/CD integration

**Lifecycle:**
- Created: Initial project setup
- Updated: As testing patterns evolve
- Referenced by: Developer Agent, Testing Agent

**Note:** Detailed testing patterns are in `.claude/skills/flutter_testing/`

---

### 5. Implementation Notes (As-Built Documentation)

**Purpose:** Document how implementation differs from design, actual decisions made
**Created by:** Developer Agent
**When:** After implementation, before handoff to Testing (Developer Phase 4)
**Location:** Added to Technical Design document as new section

**Format:** Add section to `Docs/Technical_Designs/[Feature_Name]_Technical_Design.md`:

```markdown
## Implementation Notes

**Implemented by:** Developer Agent
**Date:** [Date]
**PRs:** #XXX, #XXX, #XXX

### Deviations from Design
- [Any changes from original design with rationale]

### Actual Implementation
- **File locations:** [Actual paths if different from design]
- **Patterns used:** [Confirm which patterns were followed]

### Edge Cases Handled
- [Edge cases discovered and handled during implementation]

### Known Limitations
- [Any technical debt or limitations]
- [Future improvement opportunities]

### Testing Coverage
- Unit tests: [X%]
- Widget tests: [X%]
- Integration tests: [List of flows tested]
```

**Lifecycle:**
- Created: Once, after all implementation tasks complete
- Updated: Rarely (only if significant post-deployment changes)

---

### 6. Release Documentation

**Purpose:** Document what's in each release for users and developers
**Created by:** Deployment Agent
**When:** During deployment preparation (Deployment Phase 2)
**Location:**
- `CHANGELOG.md` (root level, version controlled)
- `Docs/Releases/release_notes_v[X.Y.Z].md` (user-facing, archived)

**Naming Convention:**
- **CHANGELOG:** `CHANGELOG.md` (single file, all releases)
- **Release Notes:** `release_notes_v[X.Y.Z].md` (one per release)
  - Example: `release_notes_v1.2.0.md`
  - Example: `release_notes_v1.4.0.md`

**Lifecycle:**
- Created: Once per release
- Updated: Never (immutable release record)

---

## Naming Conventions

### General Rules

1. **Use PascalCase** for all documentation files
   - `ArchitectureOverview.md`
   - `Dark_Mode_Technical_Design.md`

2. **Be descriptive but concise**
   - `Exercise_Library_PRD.md`
   - `DataModels.md`

3. **Use underscores for multi-word names in PRDs and Technical Designs**
   - `Dark_Mode_Technical_Design.md`
   - `Enhanced_Progress_Tracking_PRD.md`

4. **Always include suffix for typed documents**
   - PRDs: `[Feature_Name]_PRD.md`
   - Technical Designs: `[Feature_Name]_Technical_Design.md`

5. **Version numbers in release notes**
   - `release_notes_v1.2.0.md`

### Specific Patterns

| Document Type | Pattern | Example |
|---------------|---------|---------|
| Architecture | `[Topic].md` | `ArchitectureOverview.md` |
| PRD | `[Feature_Name]_PRD.md` | `Exercise_Library_PRD.md` |
| Technical Design | `[Feature_Name]_Technical_Design.md` | `Dark_Mode_Technical_Design.md` |
| Release Notes | `release_notes_v[X.Y.Z].md` | `release_notes_v1.2.0.md` |

---

## Directory Structure

```
Docs/
├── README.md                                      # Guide to documentation (index)
├── Documentation_Lifecycle.md                     # This document
├── CurrentScreens.md                              # Screen inventory and status
│
├── Architecture/                                  # Core architecture docs
│   ├── ArchitectureOverview.md
│   ├── DataModels.md
│   ├── SecurityRules.md
│   ├── StateManagement.md
│   └── FirestoreValidationStrategy.md
│
├── PRDs/                                          # Product Requirements Documents
│   ├── Exercise_Library_PRD.md
│   ├── Workout_Templates_PRD.md
│   ├── Enhanced_Progress_Tracking_PRD.md
│   └── Habit_Tracker_Monthly_Swipe_View_PRD.md
│
├── Technical_Designs/                             # Feature technical designs
│   ├── Dark_Mode_Technical_Design.md
│   ├── Color_Scheme_Selector_Technical_Design.md
│   ├── Exercise_Library_Technical_Design.md
│   ├── Workout_Templates_Technical_Design.md
│   └── [Future_Feature]_Technical_Design.md
│
├── Testing/                                       # Testing documentation
│   ├── TestingFramework.md
│   ├── TestClassification.md
│   └── CI_Integration_Tests_Guide.md
│
├── Releases/                                      # Release notes archive
│   ├── release_notes_v1.1.0.md
│   ├── release_notes_v1.2.0.md
│   └── release_notes_v1.4.0.md
│
└── Archive/                                       # Deprecated documents
    ├── original_README.md
    └── [archived files]
```

**Root Level Files:**
- `CHANGELOG.md` - Version controlled changelog (stays at root)

---

## Creation Workflow

### By Agent

| Agent | Creates | When | Location |
|-------|---------|------|----------|
| **BA** | PRD | Phase 2: After requirements gathering | `Docs/PRDs/` |
| **BA** | Feature Issue | Phase 3: After PRD created | GitHub |
| **SA** | Technical Design | Phase 2: After reading PRD | `Docs/Technical_Designs/` |
| **SA** | Task Issues | Phase 3: After design complete | GitHub |
| **SA** | Architecture Docs | As needed: When introducing patterns | `Docs/Architecture/` |
| **Developer** | Implementation Notes | Phase 4: Before handoff to Testing | Added to Technical Design |
| **Developer** | Code Comments | During implementation | Inline in code |
| **Testing** | Test Reports | Phase 4: After test execution | GitHub issue comments |
| **QA** | QA Reports | Phase 3: After manual testing | GitHub issue comments |
| **Deployment** | Release Notes | Phase 2: During artifact preparation | `Docs/Releases/` |
| **Deployment** | CHANGELOG | Phase 2: Update existing file | Root level |
| **Deployment** | GitHub Release | Phase 6: After deployment confirmed | GitHub Releases |

### By Phase (Full Feature Lifecycle)

**1. Requirements Phase (BA Agent)**
- Create PRD in `Docs/PRDs/[Feature_Name]_PRD.md`
- Create Feature Issue in GitHub with PRD link
- Add `requirements-complete` label when done

**2. Design Phase (SA Agent)**
- Create Technical Design in `Docs/Technical_Designs/`
- Create Task Issues in GitHub (one per implementation task)
- Link Technical Design to PRD and Feature Issue
- Update Architecture docs if new patterns introduced

**3. Implementation Phase (Developer Agent)**
- Write code following Technical Design
- Create PRs for each task
- Add Implementation Notes to Technical Design before handoff

**4. Testing Phase (Testing Agent)**
- Verify tests pass
- Add test results as GitHub issue comment

**5. QA Phase (QA Agent)**
- Manual testing
- Add QA report as GitHub issue comment
- Create bug issues if problems found

**6. Deployment Phase (Deployment Agent)**
- Create release notes in `Docs/Releases/`
- Update `CHANGELOG.md`
- Create GitHub Release
- Close Feature Issue

---

## Update Guidelines

### When to Update Existing Documents

**PRDs:**
- Rarely update after approval
- Only if fundamental requirements change (get user approval)
- Status tracked via GitHub issue labels

**Technical Designs:**
- SA updates if design changes before implementation
- Developer adds "Implementation Notes" section after implementation
- Don't update the original design - add notes to show deviations

**Architecture Docs:**
- Update when patterns evolve
- Update when new features extend existing components
- Living documents - keep current with codebase

**Testing Framework:**
- Update as testing patterns mature
- Update when new testing strategies introduced

**CHANGELOG:**
- Add new section for each release
- Never modify past release entries

**Release Notes:**
- Never modify (immutable release record)
- Create new file for each version

---

## Best Practices

### Do:
- Follow naming conventions consistently
- Link documents to GitHub issues
- Update architecture docs when patterns change
- Add Implementation Notes to Technical Designs
- Keep CHANGELOG.md updated with every release
- Use proper directory structure

### Don't:
- Create orphaned documents without links
- Mix business requirements into technical designs
- Put technical details in PRDs (keep business-focused)
- Modify release notes after publishing
- Skip documenting architectural decisions
- Create documentation in wrong directory

---

## Quick Reference

**"Where does this document go?"**

| Document Type | Location | Example |
|---------------|----------|---------|
| Business requirements | `Docs/PRDs/` | `Exercise_Library_PRD.md` |
| Technical design | `Docs/Technical_Designs/` | `Dark_Mode_Technical_Design.md` |
| Architecture pattern | `Docs/Architecture/` | `StateManagement.md` |
| Testing guide | `Docs/Testing/` | `TestingFramework.md` |
| Release notes | `Docs/Releases/` | `release_notes_v1.2.0.md` |
| Changelog | Root level | `CHANGELOG.md` |
| Deprecated | `Docs/Archive/` | `original_README.md` |

**"Who creates this?"**

- PRD -> BA Agent
- Technical Design -> SA Agent
- Implementation Notes -> Developer Agent
- Release Notes/Changelog -> Deployment Agent
- Architecture Docs -> SA Agent (or any agent discovering patterns)
- Test/QA Reports -> GitHub comments (not separate docs)

---

**Last Updated:** 2026-02-13
**Maintained By:** All agents following this lifecycle
