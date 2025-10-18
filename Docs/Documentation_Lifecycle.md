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
**Location:** Notion "Product Requirements" database
**Format:** Notion page

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
- Status transitions: "Requirements Gathering" → "Ready for Design" → "Design Complete" → "In Development" → "Testing" → "QA" → "Deployed"

**Linked to:**
- GitHub Feature Issue (bidirectional link)
- Technical Design (from Technical Design to PRD)

---

### 2. Technical Design Document

**Purpose:** Define technical architecture, component design, and implementation approach
**Created by:** SA Agent
**When:** After PRD approved, before implementation (SA Phase 2)
**Location:** Hybrid approach:
- **Summary:** Notion "Technical Designs" database (for tracking/metadata)
- **Detailed:** `Docs/Technical_Designs/[Feature_Name]_Technical_Design.md`

**Naming Convention:** `[Feature_Name]_Technical_Design.md`
- Use PascalCase for multi-word features
- Example: `Dark_Mode_Technical_Design.md`
- Example: `Analytics_Stat_Card_Contrast_Fix.md`
- Example: `Biometric_Authentication_Technical_Design.md`

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
- Status transitions: "In Progress" → "Ready for Review" → "Approved" → "In Development"

**Linked to:**
- Notion PRD (parent requirement)
- GitHub Feature Issue
- GitHub Task Issues (child tasks)

**Template:** See `.claude/skills/notion_documentation/` for complete template

---

### 3. Architectural/Framework Documents

**Purpose:** Document enduring architectural patterns, frameworks, and system design
**Created by:** SA Agent (initially), any agent (when discovering patterns)
**When:**
- Initial project setup
- When introducing new architectural patterns
- When documenting discovered patterns for reuse

**Location:** `Docs/Architecture/` or `Docs/Components/`

**Types:**

#### A. Core Architecture Documents
**Location:** `Docs/Architecture/`

**Naming Convention:** `[Topic].md` (PascalCase)

**Examples:**
- `ArchitectureOverview.md` - Overall system architecture
- `DataModels.md` - Database schema and Firestore structure
- `SecurityRules.md` - Firebase security rules implementation
- `StateManagement.md` - State management patterns (Provider/Riverpod/etc)

#### B. Component Documentation
**Location:** `Docs/Components/`

**Naming Convention:** `[ComponentName].md` (PascalCase)

**Examples:**
- `Authentication.md` - Auth system architecture
- `DuplicationSystem.md` - Workout duplication logic
- `ExerciseSetManagement.md` - Exercise and set handling
- `FirestoreService.md` - Firestore interaction patterns
- `UIComponents.md` - Reusable UI component patterns

#### C. Feature Documentation
**Location:** `Docs/Features/`

**Naming Convention:** `[FeatureName].md` (PascalCase)

**Examples:**
- `AnalyticsScreen.md` - Analytics feature documentation
- `EditDeleteFunctionality.md` - Edit/delete workflow
- `CurrentScreens.md` - Screen inventory and status

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
**Location:** `Docs/Testing/TestingFramework.md`

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

**Note:** Detailed testing patterns are now in `.claude/skills/flutter_testing/`

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
- `release_notes_v[X.Y.Z].md` (user-facing, archived in `Docs/Releases/`)

**Naming Convention:**
- **CHANGELOG:** `CHANGELOG.md` (single file, all releases)
- **Release Notes:** `release_notes_v[X.Y.Z].md` (one per release)
  - Example: `release_notes_v1.2.0.md`
  - Example: `release_notes_v2.0.0.md`

**CHANGELOG.md Format:**
```markdown
# Changelog

## [1.2.0] - 2025-10-09

### Added
- Dark mode theme support (#1)
- Theme toggle in Settings screen (#13)

### Changed
- Enhanced Settings screen UI (#13)

### Fixed
- Theme persistence across app restarts

**Full Implementation:**
- Task #10: Add SharedPreferences dependency
- Task #11: Create ThemeProvider
[...]

**PRs:** #101, #102, #103
```

**Release Notes Format:**
```markdown
# What's New in Version 1.2.0

## Dark Mode Support
Customize your FitTrack experience with dark mode! Reduce eye strain and save battery.

### New Features
- Dark mode theme option in Settings
- Automatic theme switching based on system preferences

### Improvements
- Enhanced Settings screen navigation

---

Thank you for using FitTrack!
```

**Lifecycle:**
- Created: Once per release
- Updated: Never (immutable release record)

---

### 7. Process Documentation

**Purpose:** Document agent workflows, skills, and development processes
**Created by:** User or Claude (meta-documentation)
**When:** As needed to improve workflow
**Location:** `Docs/Process/`

**Examples:**
- `Skills_Migration_Summary.md` - Skills extraction documentation
- `Documentation_Lifecycle.md` - This document
- `Agent_Workflow_Guide.md` - How agents work together

---

## Naming Conventions

### General Rules

1. **Use PascalCase** for all documentation files
   - ✅ `ArchitectureOverview.md`
   - ✅ `Dark_Mode_Technical_Design.md`
   - ❌ `architecture-overview.md`
   - ❌ `dark_mode_technical_design.md`

2. **Be descriptive but concise**
   - ✅ `BiometricAuthentication.md`
   - ❌ `Auth.md` (too vague)
   - ❌ `BiometricAuthenticationSystemDocumentation.md` (too verbose)

3. **Use underscores for multi-word features in Technical Designs**
   - ✅ `Dark_Mode_Technical_Design.md`
   - ✅ `User_Profile_Settings_Technical_Design.md`
   - ❌ `DarkModeTechnicalDesign.md` (hard to read)

4. **Always include suffix for Technical Designs**
   - ✅ `Dark_Mode_Technical_Design.md`
   - ❌ `Dark_Mode.md` (ambiguous - feature or design?)

5. **Version numbers in release notes**
   - ✅ `release_notes_v1.2.0.md`
   - ❌ `release_notes_1.2.0.md`
   - ❌ `v1.2.0_release_notes.md`

### Specific Patterns

| Document Type | Pattern | Example |
|---------------|---------|---------|
| Architecture | `[Topic].md` | `ArchitectureOverview.md` |
| Component | `[ComponentName].md` | `Authentication.md` |
| Feature | `[FeatureName].md` | `AnalyticsScreen.md` |
| Technical Design | `[Feature_Name]_Technical_Design.md` | `Dark_Mode_Technical_Design.md` |
| Release Notes | `release_notes_v[X.Y.Z].md` | `release_notes_v1.2.0.md` |
| Process | `[Process_Name].md` | `Skills_Migration_Summary.md` |

---

## Directory Structure

```
Docs/
├── README.md                                      # Guide to documentation (index)
├── Documentation_Lifecycle.md                     # This document
│
├── Architecture/                                  # Core architecture docs
│   ├── ArchitectureOverview.md
│   ├── DataModels.md
│   ├── SecurityRules.md
│   ├── StateManagement.md
│   └── FirestoreValidationStrategy.md
│
├── Components/                                    # Component documentation
│   ├── Authentication.md
│   ├── DuplicationSystem.md
│   ├── ExerciseSetManagement.md
│   ├── FirestoreService.md
│   └── UIComponents.md
│
├── Features/                                      # Feature-specific docs
│   ├── AnalyticsScreen.md
│   ├── EditDeleteFunctionality.md
│   └── CurrentScreens.md
│
├── Testing/                                       # Testing documentation
│   └── TestingFramework.md
│
├── Technical_Designs/                             # Feature technical designs
│   ├── Dark_Mode_Technical_Design.md
│   ├── Analytics_Stat_Card_Contrast_Fix.md
│   └── [Future_Feature]_Technical_Design.md
│
├── Releases/                                      # Release notes archive
│   ├── release_notes_v1.0.0.md
│   ├── release_notes_v1.1.0.md
│   └── release_notes_v1.2.0.md
│
├── Process/                                       # Process documentation
│   └── Skills_Migration_Summary.md
│
└── Archive/                                       # Deprecated documents
    └── original_README.md
```

**Root Level Files:**
- `CHANGELOG.md` - Version controlled changelog (stays at root)
- `README.md` - Project overview (if exists, stays at root)

---

## Creation Workflow

### By Agent

| Agent | Creates | When | Location |
|-------|---------|------|----------|
| **BA** | PRD | Phase 2: After requirements gathering | Notion |
| **BA** | Feature Issue | Phase 3: After PRD created | GitHub |
| **SA** | Technical Design (summary) | Phase 2: After reading PRD | Notion |
| **SA** | Technical Design (detailed) | Phase 2: Same time as summary | `Docs/Technical_Designs/` |
| **SA** | Task Issues | Phase 3: After design complete | GitHub |
| **SA** | Architecture Docs | As needed: When introducing patterns | `Docs/Architecture/` or `Docs/Components/` |
| **Developer** | Implementation Notes | Phase 4: Before handoff to Testing | Added to Technical Design |
| **Developer** | Code Comments | During implementation | Inline in code |
| **Testing** | Test Reports | Phase 4: After test execution | GitHub issue comments |
| **QA** | QA Reports | Phase 3: After manual testing | GitHub issue comments |
| **Deployment** | Release Notes | Phase 2: During artifact preparation | `Docs/Releases/` |
| **Deployment** | CHANGELOG | Phase 2: Update existing file | Root level |
| **Deployment** | GitHub Release | Phase 6: After deployment confirmed | GitHub Releases |

### By Phase (Full Feature Lifecycle)

**1. Requirements Phase (BA Agent)**
- ✅ Create PRD in Notion
- ✅ Create Feature Issue in GitHub
- ✅ Link PRD ↔ GitHub Issue bidirectionally

**2. Design Phase (SA Agent)**
- ✅ Create Technical Design summary in Notion
- ✅ Create detailed Technical Design in `Docs/Technical_Designs/`
- ✅ Create Task Issues in GitHub (one per implementation task)
- ✅ Link Technical Design → PRD, Feature Issue, Task Issues
- 📝 Update Architecture/Component docs if new patterns introduced

**3. Implementation Phase (Developer Agent)**
- ✅ Write code following Technical Design
- ✅ Create PRs for each task
- ✅ Add Implementation Notes to Technical Design before handoff

**4. Testing Phase (Testing Agent)**
- ✅ Verify tests pass
- ✅ Add test results as GitHub issue comment

**5. QA Phase (QA Agent)**
- ✅ Manual testing
- ✅ Add QA report as GitHub issue comment
- 📝 Create bug issues if problems found

**6. Deployment Phase (Deployment Agent)**
- ✅ Create release notes in `Docs/Releases/`
- ✅ Update `CHANGELOG.md`
- ✅ Create GitHub Release
- ✅ Update Notion PRD status to "Deployed"
- ✅ Close Feature Issue

---

## Update Guidelines

### When to Update Existing Documents

**PRDs (Notion):**
- ❌ Rarely update after approval
- ✅ Only if fundamental requirements change (get user approval)
- Status updates via properties, not content changes

**Technical Designs:**
- ✅ SA updates if design changes before implementation
- ✅ Developer adds "Implementation Notes" section after implementation
- ❌ Don't update the original design - add notes to show deviations

**Architecture/Component Docs:**
- ✅ Update when patterns evolve
- ✅ Update when new features extend existing components
- ✅ Living documents - keep current with codebase

**Testing Framework:**
- ✅ Update as testing patterns mature
- ✅ Update when new testing strategies introduced
- Reference skills for detailed patterns

**CHANGELOG:**
- ✅ Add new section for each release
- ❌ Never modify past release entries

**Release Notes:**
- ❌ Never modify (immutable release record)
- ✅ Create new file for each version

---

## Best Practices

### Do:

- ✅ Follow naming conventions consistently
- ✅ Link documents bidirectionally (Notion ↔ GitHub, Design ↔ PRD)
- ✅ Update architecture docs when patterns change
- ✅ Add Implementation Notes to Technical Designs
- ✅ Keep CHANGELOG.md updated with every release
- ✅ Use proper directory structure
- ✅ Reference skills for procedural knowledge (don't duplicate)

### Don't:

- ❌ Create orphaned documents without links
- ❌ Mix business requirements into technical designs
- ❌ Put technical details in PRDs (keep business-focused)
- ❌ Modify release notes after publishing
- ❌ Skip documenting architectural decisions
- ❌ Create documentation in wrong directory
- ❌ Use inconsistent naming conventions

---

## Quick Reference

**"Where does this document go?"**

| Document Type | Location | Example |
|---------------|----------|---------|
| Business requirements | Notion PRD | (Notion only) |
| Technical design | `Docs/Technical_Designs/` | `Dark_Mode_Technical_Design.md` |
| Architecture pattern | `Docs/Architecture/` | `StateManagement.md` |
| Component guide | `Docs/Components/` | `Authentication.md` |
| Feature overview | `Docs/Features/` | `AnalyticsScreen.md` |
| Testing guide | `Docs/Testing/` | `TestingFramework.md` |
| Release notes | `Docs/Releases/` | `release_notes_v1.2.0.md` |
| Changelog | Root level | `CHANGELOG.md` |
| Process docs | `Docs/Process/` | `Skills_Migration_Summary.md` |
| Deprecated | `Docs/Archive/` | `original_README.md` |

**"Who creates this?"**

- PRD → BA Agent
- Technical Design → SA Agent
- Implementation Notes → Developer Agent
- Release Notes/Changelog → Deployment Agent
- Architecture Docs → SA Agent (or any agent discovering patterns)
- Test/QA Reports → GitHub comments (not separate docs)

**"When is this created?"**

- PRD → After requirements gathering
- Technical Design → After PRD approved
- Implementation Notes → After implementation, before testing
- Release Notes → During deployment preparation
- Architecture Docs → As needed when patterns introduced

---

## For Agents

Each agent should reference this document to understand:

1. **What documentation you create** - See "Creation Workflow" table
2. **When to create it** - See your agent's phase in workflow
3. **Where to put it** - See "Directory Structure"
4. **How to name it** - See "Naming Conventions"
5. **How to link it** - See "Update Guidelines"

**Skills integration:**
- Detailed templates → See `.claude/skills/notion_documentation/`
- Procedural standards → See `.claude/skills/github_workflow/`
- This document defines **what** and **when**, skills define **how**

---

**Last Updated:** 2025-10-17
**Maintained By:** All agents following this lifecycle
