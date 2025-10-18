---
name: Notion Documentation Standards
description: Templates and standards for creating PRDs, technical designs, and documentation in Notion
---

# Notion Documentation Standards Skill

This skill provides standardized templates and best practices for creating product requirements documents (PRDs), technical designs, and other documentation in Notion.

## Notion Workspace Structure

**Workspace:** FitTrack Development

**Databases:**
- **Product Requirements** - Feature PRDs and specifications
- **User Stories** - User stories linked to PRDs
- **Technical Designs** - Architecture and design documents
- **Decisions & Notes** - Meeting notes and key decisions

**Templates:**
- Feature PRD Template - For new feature requirements
- Technical Design Template - For technical architecture

## Product Requirements Document (PRD) Template

### When to Create
- BA Agent creates PRDs after gathering requirements from user
- One PRD per feature
- Created in "Product Requirements" database

### PRD Structure

```markdown
# [Feature Name]

## Overview
[2-3 sentence description of what and why]

## User Problem
[The problem this solves]

## User Stories

### US-1: [Story Name]
As a [user type], I want [goal] so that [benefit]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### US-2: [Story Name]
As a [user type], I want [goal] so that [benefit]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

### US-3: [Story Name]
As a [user type], I want [goal] so that [benefit]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

[Continue for 3-7 user stories total]

## Functional Requirements
- FR-1: [Requirement]
- FR-2: [Requirement]
- FR-3: [Requirement]

## Non-Functional Requirements
- NFR-1: Performance - [specific targets]
- NFR-2: Accessibility - [specific requirements]
- NFR-3: Platform Consistency - [requirements]

## User Flow
1. User does X
2. System responds with Y
3. User sees/does Z

## Edge Cases & Error Handling
- What happens if [error condition]?
- What happens when [edge case]?

## Technical Considerations
- Platform-specific requirements
- Dependencies on existing systems
- Security/privacy concerns
- Offline behavior

## Success Metrics
- How we'll measure success
- KPIs to track

## Overall Acceptance Criteria
- [ ] High-level criterion 1
- [ ] High-level criterion 2
- [ ] High-level criterion 3
```

### PRD Properties to Set

| Property | Value |
|----------|-------|
| **Status** | "Requirements Gathering" → "Ready for Design" → "Design Complete" → "In Development" → "Testing" → "QA" → "Deployed" |
| **Priority** | Critical / High / Medium / Low |
| **Platform** | iOS / Android / Both |
| **Feature Type** | New Feature / Enhancement / Bug Fix |
| **GitHub Issue** | [Link to feature issue] |
| **Assignee** | Current responsible agent |

### User Stories Best Practices

**DO keep user stories in the PRD** - Don't create separate entries in "User Stories" database

**User Story Format:**
```
As a [specific user type],
I want [specific goal],
so that [specific benefit/value]
```

**Examples:**

✅ Good:
```
As a fitness enthusiast using the app in a dark room,
I want to switch to dark mode,
so that I can use the app comfortably without eye strain
```

❌ Bad:
```
As a user, I want dark mode, so it looks better
```

**Acceptance Criteria Guidelines:**
- 3-5 criteria per story
- Specific and testable
- Include platform requirements
- Include error cases
- Include accessibility requirements

**Example:**
```
**Acceptance Criteria:**
- [ ] Toggle appears in Settings screen
- [ ] Theme persists across app restarts
- [ ] Theme applies to all screens including Analytics
- [ ] Toggle is accessible with screen reader
- [ ] Works on both iOS and Android
```

## Technical Design Document Template

### When to Create
- SA Agent creates technical designs after requirements approval
- One design per feature
- Created in "Technical Designs" database

**See [Docs/Documentation_Lifecycle.md](../../Docs/Documentation_Lifecycle.md) for complete lifecycle information.**

### Naming Convention

**For detailed Technical Design markdown files:**
- Location: `Docs/Technical_Designs/[Feature_Name]_Technical_Design.md`
- Pattern: `[Feature_Name]_Technical_Design.md`
- Use PascalCase with underscores between words
- Always include `_Technical_Design` suffix

**Examples:**
- ✅ `Dark_Mode_Technical_Design.md`
- ✅ `Analytics_Stat_Card_Contrast_Fix.md`
- ✅ `Biometric_Authentication_Technical_Design.md`
- ❌ `DarkModeTechnicalDesign.md` (hard to read without underscores)
- ❌ `Dark_Mode.md` (missing suffix, ambiguous)

**See [Docs/Documentation_Lifecycle.md](../../Docs/Documentation_Lifecycle.md) § Naming Conventions for complete naming standards.**

### Design Structure

```markdown
# [Feature Name] - Technical Design

## Overview
[Brief description linking to PRD]

**Related Documents:**
- PRD: [Link to Notion PRD]
- GitHub Issue: [Link to feature issue]

## Architecture Overview

### High-Level Approach
[Describe the overall technical approach]

### Components Involved
- Component 1 - [Purpose]
- Component 2 - [Purpose]
- Component 3 - [Purpose]

### Design Decisions

#### Decision 1: [Topic]
**Options Considered:**
1. Option A - [Pros/cons]
2. Option B - [Pros/cons]

**Chosen:** Option [X]

**Rationale:** [Why this option is best]

#### Decision 2: [Topic]
[Same format]

## Detailed Design

### Data Models
[If new models or changes to existing]

```dart
class ThemeProvider extends ChangeNotifier {
  // Fields
  ThemeMode _themeMode;

  // Methods
  Future<void> setThemeMode(ThemeMode mode);
  ThemeMode get currentThemeMode;
}
```

### File Structure
```
lib/
  providers/
    theme_provider.dart       [NEW] - Theme state management
  screens/
    settings/
      settings_screen.dart    [MODIFIED] - Add theme toggle
test/
  providers/
    theme_provider_test.dart  [NEW] - Unit tests
```

### Implementation Approach

#### Phase 1: Foundation
[What to build first]

#### Phase 2: Integration
[How pieces connect]

#### Phase 3: Testing
[Test strategy]

### Dependencies
- Package: shared_preferences ^2.2.2
- Existing: lib/providers/auth_provider.dart (pattern reference)

### Testing Strategy

**Unit Tests:**
- ThemeProvider state changes
- Persistence logic
- Coverage target: 90%+

**Widget Tests:**
- Settings toggle renders
- Theme changes apply
- Accessibility labels present

**Integration Tests:**
- Theme persists across app restart
- All screens respond to theme changes

## Implementation Tasks

### Task Breakdown
[List of GitHub task issues to be created]

1. **Add shared_preferences dependency**
   - Update pubspec.yaml
   - Run flutter pub get

2. **Create ThemeProvider**
   - Implement ChangeNotifier pattern
   - Add persistence with SharedPreferences
   - Write unit tests

3. **Integrate in main.dart**
   - Register provider
   - Wire up to MaterialApp

[Continue for all tasks...]

### Task Dependencies
```
Task 1 → Task 2 → Task 3
              ↓
            Task 4
```

## Security Considerations
[Any security implications]

## Performance Considerations
[Any performance implications]

## Accessibility Considerations
[How this meets accessibility requirements]

## Platform-Specific Notes

### iOS
[iOS-specific considerations]

### Android
[Android-specific considerations]

## Rollback Plan
[How to undo if needed]

## Future Enhancements
[Potential future work, out of scope for now]
```

### Design Properties to Set

| Property | Value |
|----------|-------|
| **Status** | "In Progress" → "Ready for Review" → "Approved" → "In Development" |
| **Related PRD** | [Link to PRD] |
| **GitHub Issue** | [Link to feature issue] |
| **Assigned Developer** | [Who will implement] |
| **Complexity** | Low / Medium / High |

## Linking Strategy

### Notion ↔ GitHub Bidirectional Links

**In Notion PRD/Design:**
- Set "GitHub Issue" property to: `https://github.com/owner/repo/issues/XX`

**In GitHub Issue:**
- Add in description: `**Notion PRD:** https://notion.so/...`

**In Pull Requests:**
- Add in description: `**Technical Design:** https://notion.so/...`

### Internal Notion Links

**Link Technical Design to PRD:**
- Set "Related PRD" property in Technical Design
- Reference in Overview section

**Link User Stories to PRD:**
- Keep stories embedded in PRD (don't create separate entries)
- Only create separate if stories need independent tracking

## Status Transition Guide

### PRD Status Transitions

1. **Requirements Gathering** - BA is collecting information
2. **Ready for Design** - User approved requirements, awaiting SA
3. **Design Complete** - SA finished design
4. **In Development** - Developer working on implementation
5. **Testing** - Testing Agent running tests
6. **QA** - QA Agent reviewing
7. **Deployed** - Live in production

**Who updates:**
- BA: Requirements Gathering → Ready for Design
- SA: Ready for Design → Design Complete
- Developer: Design Complete → In Development
- Testing: In Development → Testing
- QA: Testing → QA
- Deployment: QA → Deployed

### Design Status Transitions

1. **In Progress** - SA is writing design
2. **Ready for Review** - Design complete, awaiting user approval
3. **Approved** - User approved, ready for implementation
4. **In Development** - Developer implementing

## Documentation Best Practices

### Writing Style

**Be specific:**
- ✅ "Toggle persists theme choice using SharedPreferences"
- ❌ "Toggle saves the theme"

**Be measurable:**
- ✅ "Target 90%+ test coverage"
- ❌ "Good test coverage"

**Be actionable:**
- ✅ "As a logged-in user, I want..."
- ❌ "Users should be able to..."

**Include examples:**
- Show code snippets for data models
- Show UI mockups for screens
- Show flow diagrams for complex logic

### Common Pitfalls to Avoid

❌ **Vague requirements:**
```
The app should have good UX
The feature should be fast
It should be secure
```

✅ **Specific requirements:**
```
NFR-1: Performance - Theme switch applies within 100ms
NFR-2: Accessibility - All toggles have semantic labels for screen readers
NFR-3: Security - Theme preference stored locally, not synced to cloud
```

❌ **Missing edge cases:**
```
User toggles dark mode
```

✅ **Complete edge cases:**
```
- What if user toggles while screens are loading?
- What if SharedPreferences save fails?
- What if system theme changes while app is open?
- What if user has "auto dark mode" set on OS?
```

❌ **Implementation details in PRD:**
```
Use Provider package with ChangeNotifier
Store in SharedPreferences with key "theme_mode"
```

✅ **Requirements-focused PRD:**
```
Theme choice must persist across app restarts
Theme must apply to all screens consistently
```

(Implementation details belong in Technical Design, not PRD)

## Quality Checklist

### Before Marking PRD as "Ready for Design"

- [ ] Clear problem statement exists
- [ ] 3+ user stories with acceptance criteria
- [ ] Each story is testable
- [ ] Edge cases documented
- [ ] Success metrics defined
- [ ] Platform requirements specified
- [ ] Dependencies identified
- [ ] User confirmed accuracy
- [ ] GitHub issue created and linked
- [ ] Properties set correctly

### Before Marking Design as "Ready for Review"

- [ ] Links to PRD and GitHub issue
- [ ] Architecture approach explained
- [ ] Design decisions documented with rationale
- [ ] Data models defined (if applicable)
- [ ] File structure clear
- [ ] Implementation tasks broken down
- [ ] Testing strategy defined
- [ ] Dependencies identified
- [ ] Security considerations addressed
- [ ] Platform-specific notes included
- [ ] Code examples provided

## Templates Quick Reference

**Access templates:**
1. Go to appropriate database
2. Click "New" → Select template

**Feature PRD Template** - Use for all new features
**Technical Design Template** - Use for all technical designs

**Custom templates** - Create if you need specialized docs (e.g., "API Integration Design", "Performance Analysis")

## Error Handling

**If Notion creation fails:**
1. Save content as local markdown file
2. Retry once
3. If still failing: notify user, continue with GitHub issue
4. Provide markdown for user to paste manually

**If linking fails:**
1. Create documents first
2. Add links manually via properties
3. Verify bidirectional links work

**If template not found:**
1. Use manual structure from this skill
2. Ask user to create template for future use

## Examples

### Example PRD: Dark Mode Support

[See actual PRD in Notion workspace for reference]

### Example Technical Design: Theme System

[See actual design in Notion workspace for reference]
