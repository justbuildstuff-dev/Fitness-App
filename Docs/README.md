# FitTrack Documentation

This directory contains all technical documentation for the FitTrack mobile application.

## Quick Navigation

| Category | Location | Purpose |
|----------|----------|---------|
| **Architecture** | [`Architecture/`](Architecture/) | Core system architecture and patterns |
| **PRDs** | [`PRDs/`](PRDs/) | Product Requirements Documents |
| **Technical Designs** | [`Technical_Designs/`](Technical_Designs/) | Feature implementation designs |
| **Testing** | [`Testing/`](Testing/) | Testing framework, strategies, CI guides |
| **Releases** | [`Releases/`](Releases/) | Release notes archive |
| **Archive** | [`Archive/`](Archive/) | Deprecated/legacy documents |

## Documentation Types

### Core Architecture (`Architecture/`)

Foundational architectural decisions and system-wide patterns:

- **[ArchitectureOverview.md](Architecture/ArchitectureOverview.md)** - Overall system architecture
- **[DataModels.md](Architecture/DataModels.md)** - Firestore data model and schema
- **[SecurityRules.md](Architecture/SecurityRules.md)** - Firebase security rules implementation
- **[StateManagement.md](Architecture/StateManagement.md)** - State management patterns (Provider)
- **[FirestoreValidationStrategy.md](Architecture/FirestoreValidationStrategy.md)** - Data validation approach

### PRDs (`PRDs/`)

Product Requirements Documents created by BA Agent:

- **[Exercise_Library_PRD.md](PRDs/Exercise_Library_PRD.md)** - Exercise library feature
- **[Workout_Templates_PRD.md](PRDs/Workout_Templates_PRD.md)** - Workout templates feature
- **[Enhanced_Progress_Tracking_PRD.md](PRDs/Enhanced_Progress_Tracking_PRD.md)** - Progress tracking & charts
- **[Habit_Tracker_Monthly_Swipe_View_PRD.md](PRDs/Habit_Tracker_Monthly_Swipe_View_PRD.md)** - Habit tracker

### Technical Designs (`Technical_Designs/`)

SA Agent creates these for each new feature:

- **[Workout_Templates_Technical_Design.md](Technical_Designs/Workout_Templates_Technical_Design.md)** - Templates implementation
- **[Exercise_Library_Technical_Design.md](Technical_Designs/Exercise_Library_Technical_Design.md)** - Exercise library implementation
- **[Color_Scheme_Selector_Technical_Design.md](Technical_Designs/Color_Scheme_Selector_Technical_Design.md)** - Color scheme implementation
- **[Consolidated_Workout_Screen_Technical_Design.md](Technical_Designs/Consolidated_Workout_Screen_Technical_Design.md)** - Consolidated workout screen
- **[Global_Bottom_Navigation_Bar_Technical_Design.md](Technical_Designs/Global_Bottom_Navigation_Bar_Technical_Design.md)** - Bottom nav bar
- **[Dark_Mode_Technical_Design.md](Technical_Designs/Dark_Mode_Technical_Design.md)** - Dark mode implementation
- And more (habit tracker, duplicate week enhancement)

**New designs:** Follow naming convention `[Feature_Name]_Technical_Design.md`

### Testing (`Testing/`)

Testing framework and standards:

- **[TestingFramework.md](Testing/TestingFramework.md)** - Testing strategy, patterns, and setup
- **[TestClassification.md](Testing/TestClassification.md)** - Test classification guide
- **[CI_Integration_Tests_Guide.md](Testing/CI_Integration_Tests_Guide.md)** - CI/CD integration tests guide

**Note:** Detailed testing patterns are in `.claude/skills/flutter_testing/`

### Root-Level Files

- **[CurrentScreens.md](CurrentScreens.md)** - Screen inventory and implementation status
- **[Documentation_Lifecycle.md](Documentation_Lifecycle.md)** - Documentation system master document

---

## Documentation Lifecycle

**See [Documentation_Lifecycle.md](Documentation_Lifecycle.md) for:**
- What documents exist
- Who creates them
- When they're created
- Where they live
- Naming conventions
- Update guidelines

## For Agents

### BA Agent
**Creates:**
- PRD in `Docs/PRDs/[Feature_Name]_PRD.md`
- GitHub Feature Issue with PRD link

### SA Agent
**Creates:**
- Technical Design in `Docs/Technical_Designs/[Feature_Name]_Technical_Design.md`
- Architecture docs (as needed) in `Docs/Architecture/`

### Developer Agent
**Creates:**
- Implementation Notes (added to Technical Design)
- Code comments (inline)

### Deployment Agent
**Creates:**
- Release notes in `Docs/Releases/release_notes_v[X.Y.Z].md`
- Updates `CHANGELOG.md` (root level)

---

## Naming Conventions

| Document Type | Pattern | Example |
|---------------|---------|---------|
| Architecture | `[Topic].md` | `ArchitectureOverview.md` |
| PRD | `[Feature_Name]_PRD.md` | `Exercise_Library_PRD.md` |
| Technical Design | `[Feature_Name]_Technical_Design.md` | `Dark_Mode_Technical_Design.md` |
| Release Notes | `release_notes_v[X.Y.Z].md` | `release_notes_v1.2.0.md` |

**General Rules:**
- Use PascalCase for all files
- Use underscores between words in PRDs and Technical Designs
- Be descriptive but concise

---

## Related Documentation

**In `.claude/skills/`:**
- GitHub workflow and issue templates
- Flutter testing patterns
- Flutter code quality standards
- Agent handoff protocols

**In `CLAUDE.md` (root):**
- Project overview
- Agent workflow
- Development commands
- Quick reference

---

## Adding New Documentation

### New Feature PRD
1. BA Agent creates after requirements gathering
2. Location: `Docs/PRDs/[Feature_Name]_PRD.md`
3. Link: PRD -> GitHub Issue (bidirectional)

### New Feature Technical Design
1. SA Agent creates after PRD approval
2. Location: `Docs/Technical_Designs/[Feature_Name]_Technical_Design.md`
3. Link: Technical Design -> PRD -> GitHub Issue

### New Architecture Doc
1. Created by SA Agent when introducing new patterns
2. Location: `Docs/Architecture/[Topic].md`
3. Update this README if it's a major addition

### New Release Notes
1. Deployment Agent creates during deployment prep
2. Location: `Docs/Releases/release_notes_v[X.Y.Z].md`
3. Also update `CHANGELOG.md` at root level

---

## Maintenance

**Living Documents** (update as code evolves):
- Architecture docs
- Testing framework

**Immutable Documents** (never modify after creation):
- Technical Designs (add Implementation Notes instead)
- Release notes
- CHANGELOG entries

**Deprecated Documents:**
- Move to `Archive/`
- Keep for historical reference

---

**Last Updated:** 2026-02-13
**For Questions:** See `Documentation_Lifecycle.md` or `CLAUDE.md`
