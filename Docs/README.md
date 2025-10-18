# FitTrack Documentation

This directory contains all technical documentation for the FitTrack mobile application.

## 📋 Quick Navigation

| Category | Location | Purpose |
|----------|----------|---------|
| **Architecture** | [`Architecture/`](Architecture/) | Core system architecture and patterns |
| **Components** | [`Components/`](Components/) | Component-level documentation |
| **Features** | [`Features/`](Features/) | Feature-specific documentation |
| **Technical Designs** | [`Technical_Designs/`](Technical_Designs/) | Feature implementation designs |
| **Testing** | [`Testing/`](Testing/) | Testing framework and strategies |
| **Releases** | [`Releases/`](Releases/) | Release notes archive |
| **Process** | [`Process/`](Process/) | Development process documentation |
| **Archive** | [`Archive/`](Archive/) | Deprecated/legacy documents |

## 📚 Documentation Types

### Core Architecture (`Architecture/`)

Foundational architectural decisions and system-wide patterns:

- **[ArchitectureOverview.md](Architecture/ArchitectureOverview.md)** - Overall system architecture
- **[DataModels.md](Architecture/DataModels.md)** - Firestore data model and schema
- **[SecurityRules.md](Architecture/SecurityRules.md)** - Firebase security rules implementation
- **[StateManagement.md](Architecture/StateManagement.md)** - State management patterns (Provider)
- **[FirestoreValidationStrategy.md](Architecture/FirestoreValidationStrategy.md)** - Data validation approach

### Components (`Components/`)

Component-level implementation details:

- **[Authentication.md](Components/Authentication.md)** - Authentication system
- **[DuplicationSystem.md](Components/DuplicationSystem.md)** - Workout/week duplication logic
- **[ExerciseSetManagement.md](Components/ExerciseSetManagement.md)** - Exercise and set handling
- **[FirestoreService.md](Components/FirestoreService.md)** - Firestore interaction patterns
- **[UIComponents.md](Components/UIComponents.md)** - Reusable UI components

### Features (`Features/`)

Feature-specific documentation:

- **[AnalyticsScreen.md](Features/AnalyticsScreen.md)** - Analytics feature
- **[CurrentScreens.md](Features/CurrentScreens.md)** - Screen inventory and implementation status
- **[EditDeleteFunctionality.md](Features/EditDeleteFunctionality.md)** - Edit/delete workflows

### Technical Designs (`Technical_Designs/`)

SA Agent creates these for each new feature:

- **[Dark_Mode_Technical_Design.md](Technical_Designs/Dark_Mode_Technical_Design.md)** - Dark mode implementation
- **[Analytics_Stat_Card_Contrast_Fix.md](Technical_Designs/Analytics_Stat_Card_Contrast_Fix.md)** - Contrast fix design

**New designs:** Follow naming convention `[Feature_Name]_Technical_Design.md`

### Testing (`Testing/`)

Testing framework and standards:

- **[TestingFramework.md](Testing/TestingFramework.md)** - Testing strategy, patterns, and setup

**Note:** Detailed testing patterns are in `.claude/skills/flutter_testing/`

### Process (`Process/`)

Development process and workflow documentation:

- **[Skills_Migration_Summary.md](Process/Skills_Migration_Summary.md)** - Skills extraction from agents
- **[Documentation_Lifecycle.md](../Documentation_Lifecycle.md)** - This documentation system (parent level)

---

## 📖 Documentation Lifecycle

**See [Documentation_Lifecycle.md](Documentation_Lifecycle.md) for:**
- What documents exist
- Who creates them
- When they're created
- Where they live
- Naming conventions
- Update guidelines

## 🤖 For Agents

### BA Agent
**Creates:**
- PRD in Notion (not in Docs/)
- GitHub Feature Issue

**References:** `Documentation_Lifecycle.md` for PRD structure

### SA Agent
**Creates:**
- Technical Design summary in Notion
- Technical Design detailed doc in `Technical_Designs/[Feature_Name]_Technical_Design.md`
- Architecture/Component docs (as needed)

**References:** `Documentation_Lifecycle.md`, `.claude/skills/notion_documentation/`

### Developer Agent
**Creates:**
- Implementation Notes (added to Technical Design)
- Code comments (inline)

**References:** `Documentation_Lifecycle.md`, Technical Designs

### Deployment Agent
**Creates:**
- Release notes in `Releases/release_notes_v[X.Y.Z].md`
- Updates `CHANGELOG.md` (root level)

**References:** `Documentation_Lifecycle.md`

---

## 🗂️ Naming Conventions

| Document Type | Pattern | Example |
|---------------|---------|---------|
| Architecture | `[Topic].md` | `ArchitectureOverview.md` |
| Component | `[ComponentName].md` | `Authentication.md` |
| Feature | `[FeatureName].md` | `AnalyticsScreen.md` |
| Technical Design | `[Feature_Name]_Technical_Design.md` | `Dark_Mode_Technical_Design.md` |
| Release Notes | `release_notes_v[X.Y.Z].md` | `release_notes_v1.2.0.md` |
| Process | `[Process_Name].md` | `Skills_Migration_Summary.md` |

**General Rules:**
- Use PascalCase for all files
- Use underscores in Technical Design feature names
- Be descriptive but concise
- Include appropriate suffixes (`_Technical_Design`, `_v[version]`)

---

## 🔗 Related Documentation

**In `.claude/skills/`:**
- Notion documentation templates and standards
- GitHub workflow and issue templates
- Flutter testing patterns
- Flutter code quality standards
- Agent handoff protocols

**In `CLAUDE.md` (root):**
- Project overview
- Agent workflow
- Development commands
- Quick reference

**In Notion:**
- Product Requirements Documents (PRDs)
- Technical Design summaries
- User Stories
- Decisions & Notes

---

## 🆕 Adding New Documentation

### New Feature Technical Design
1. SA Agent creates after PRD approval
2. Location: `Docs/Technical_Designs/[Feature_Name]_Technical_Design.md`
3. Also create summary in Notion "Technical Designs" database
4. Link: Technical Design → PRD → GitHub Issue

### New Architecture/Component Doc
1. Created by SA Agent when introducing new patterns
2. Location:
   - Architecture: `Docs/Architecture/[Topic].md`
   - Component: `Docs/Components/[ComponentName].md`
3. Update this README if it's a major addition

### New Release Notes
1. Deployment Agent creates during deployment prep
2. Location: `Docs/Releases/release_notes_v[X.Y.Z].md`
3. Also update `CHANGELOG.md` at root level

---

## 📝 Maintenance

**Living Documents** (update as code evolves):
- Architecture docs
- Component docs
- Feature docs
- Testing framework

**Immutable Documents** (never modify after creation):
- Technical Designs (add Implementation Notes instead)
- Release notes
- CHANGELOG entries

**Deprecated Documents:**
- Move to `Archive/`
- Add note at top explaining why archived
- Keep for historical reference

---

## 🔍 Finding Documentation

**By Agent:**
- BA Agent docs → Notion PRDs
- SA Agent docs → `Technical_Designs/`, `Architecture/`, `Components/`
- Developer notes → `Technical_Designs/` (Implementation Notes section)
- Deployment docs → `Releases/`, `CHANGELOG.md`

**By Type:**
- Business requirements → Notion
- Technical architecture → `Architecture/`
- Implementation design → `Technical_Designs/`
- Component guides → `Components/`
- Process guides → `Process/`, `.claude/`

**By Feature:**
- Check `Technical_Designs/` for implementation design
- Check `Features/` for feature-level overview
- Check Notion PRD for business requirements
- Check GitHub for issues and PRs

---

**Last Updated:** 2025-10-17
**For Questions:** See `Documentation_Lifecycle.md` or `CLAUDE.md`
