# Skills Migration Summary

This document summarizes the skills that have been created and the changes needed to agent files to reference them.

## Skills Created

All skills are located in `.claude/skills/` with the following structure:

### 1. GitHub Workflow Management
**Location:** `.claude/skills/github_workflow/SKILL.md`

**Contains:**
- Issue creation standards (Feature, Task, Bug)
- Issue lifecycle management
- PR standards and templates
- Branch naming conventions
- Label system and workflow states
- Commit message standards
- Issue linking best practices
- Main branch protection rules

**Used by:** All agents (BA, SA, Developer, Testing, QA, Deployment)

### 2. Notion Documentation Standards
**Location:** `.claude/skills/notion_documentation/SKILL.md`

**Contains:**
- PRD template structure
- Technical Design template structure
- User story format and best practices
- Property management and status transitions
- Linking strategy (Notion ↔ GitHub)
- Documentation quality standards
- Common pitfalls to avoid

**Used by:** BA Agent, SA Agent

### 3. Flutter Testing Patterns
**Location:** `.claude/skills/flutter_testing/SKILL.md`

**Contains:**
- Test file organization and naming
- Unit test structure and patterns
- Widget test structure and patterns
- Integration test setup
- Mocking dependencies (SharedPreferences, Firebase, etc.)
- Coverage requirements
- Testing best practices
- Common test patterns for FitTrack

**Used by:** Developer Agent, Testing Agent

### 4. Agent Handoff Protocol
**Location:** `.claude/skills/agent_handoff/SKILL.md`

**Contains:**
- Complete workflow overview
- Handoff checklist templates
- BA → SA handoff process
- SA → Developer handoff process
- Developer → Testing handoff process
- Testing → QA handoff process
- QA → Deployment handoff process
- QA → Developer (bug found) process
- Deployment → User (final) process
- User approval points
- Automatic vs manual handoffs

**Used by:** All agents

### 5. Flutter Code Quality Standards
**Location:** `.claude/skills/flutter_code_quality/SKILL.md`

**Contains:**
- Dart style guide adherence
- File organization and naming
- Import organization
- Code formatting standards
- Naming conventions (variables, methods, classes)
- Constants and configuration
- Comments and documentation
- Error handling patterns
- Null safety best practices
- Async/await patterns
- State management (Provider pattern)
- Widget best practices
- Performance optimization
- Accessibility standards
- Linter configuration
- Pre-commit checklist
- Code review standards
- Common anti-patterns to avoid

**Used by:** Developer Agent, SA Agent (when designing)

---

## Agent File Updates Needed

### BA Agent (`.claude/agents/ba.md`)

**Add after "Tools" section:**
```markdown
## Skills Referenced

This agent uses the following skills:

- **Notion Documentation Standards** - PRD templates, user story formats
- **GitHub Workflow Management** - Issue creation, labeling, lifecycle
- **Agent Handoff Protocol** - BA → SA handoff process

Refer to `.claude/skills/` for detailed procedures.
```

**Sections to remove/condense:**
- Detailed PRD template (reference skill instead)
- Detailed GitHub issue template (reference skill instead)
- Detailed handoff protocol (reference skill instead)

**Keep:**
- Core responsibilities
- Questioning strategy and discovery process
- Quality checklist
- Common feature patterns
- Self-checks

---

### SA Agent (`.claude/agents/sa.md`)

**Add after "Tools" section:**
```markdown
## Skills Referenced

This agent uses the following skills:

- **Notion Documentation Standards** - Technical Design templates
- **GitHub Workflow Management** - Task issue creation, linking
- **Agent Handoff Protocol** - SA → Developer handoff process
- **Flutter Code Quality Standards** - For designing testable, maintainable code

Refer to `.claude/skills/` for detailed procedures.
```

**Sections to remove/condense:**
- Detailed Technical Design template (reference skill instead)
- Detailed task issue template (reference skill instead)
- Detailed handoff protocol (reference skill instead)

**Keep:**
- Analysis & research process
- Architecture discovery methodology
- Design decision documentation
- Task breakdown strategy
- Risk identification

---

### Developer Agent (`.claude/agents/developer.md`)

**Add after "Tools" section:**
```markdown
## Skills Referenced

This agent uses the following skills:

- **GitHub Workflow Management** - PR creation, commit messages, branch naming
- **Flutter Code Quality Standards** - All code quality and style standards
- **Flutter Testing Patterns** - Unit, widget, and integration test patterns
- **Agent Handoff Protocol** - Developer → Testing handoff process

Refer to `.claude/skills/` for detailed procedures.
```

**Sections to remove/condense:**
- Detailed code quality standards (reference skill instead)
- Detailed testing patterns (reference skill instead)
- Detailed PR template (reference skill instead)
- Detailed handoff protocol (reference skill instead)

**Keep:**
- Task-by-task implementation workflow
- Sequential vs parallel task strategy
- Main branch protection emphasis
- Self-checks before handoff

---

### Testing Agent (`.claude/agents/testing.md`)

**Add after "Tools" section:**
```markdown
## Skills Referenced

This agent uses the following skills:

- **GitHub Workflow Management** - Issue and label management
- **Flutter Testing Patterns** - Test standards and coverage requirements
- **Agent Handoff Protocol** - Testing → QA (or → Developer if bugs) handoff

Refer to `.claude/skills/` for detailed procedures.
```

**Sections to remove/condense:**
- Detailed testing standards (reference skill instead)
- Detailed bug issue template (reference skill instead)
- Detailed handoff protocol (reference skill instead)

**Keep:**
- PR test result verification workflow
- Beta build creation process (label-based)
- Coverage validation process
- Main branch testing clarification (tests run on PRs, not main)

---

### QA Agent (`.claude/agents/qa.md`)

**Add after "Tools" section:**
```markdown
## Skills Referenced

This agent uses the following skills:

- **GitHub Workflow Management** - Bug issue creation, labeling
- **Agent Handoff Protocol** - QA → Deployment (or → Developer if bugs) handoff

Refer to `.claude/skills/` for detailed procedures.
```

**Sections to remove/condense:**
- Detailed bug issue template (reference skill instead)
- Detailed handoff protocol (reference skill instead)

**Keep:**
- Manual testing methodology
- Test plan creation
- Cross-platform validation process
- QA decision criteria (Approve/Approve with issues/Reject)
- Testing checklist template

---

### Deployment Agent (`.claude/agents/deployment.md`)

**Add after "Tools" section:**
```markdown
## Skills Referenced

This agent uses the following skills:

- **GitHub Workflow Management** - Release creation, issue closing
- **Agent Handoff Protocol** - Deployment → User (final) completion

Refer to `.claude/skills/` for detailed procedures.
```

**Sections to remove/condense:**
- Detailed handoff protocol (reference skill instead)

**Keep:**
- Version bumping strategy (semver)
- Release artifact preparation
- Deployment checklist
- Post-deployment monitoring
- Feature issue closing process (ONLY agent that closes feature issues)

---

## Migration Strategy

To complete the migration:

1. **Backup all agent files** (already done for ba.md)
   ```bash
   cd .claude/agents
   for file in *.md; do cp "$file" "$file.backup"; done
   ```

2. **Edit each agent file:**
   - Add "Skills Referenced" section after "Tools"
   - Remove duplicated content that now exists in skills
   - Keep agent-specific workflows and decision-making
   - Reference skills for procedures and templates

3. **Test the workflow:**
   - Invoke each agent to ensure skills are accessible
   - Verify agents can find and use skill information
   - Confirm no broken workflows

4. **Delete backups** (once verified working)
   ```bash
   cd .claude/agents
   rm *.backup
   ```

## Benefits of This Approach

1. **DRY (Don't Repeat Yourself)** - GitHub/Notion patterns documented once
2. **Consistency** - All agents use exact same standards
3. **Maintainability** - Update skill once, all agents benefit
4. **Clarity** - Agent files focus on their unique workflow, not shared procedures
5. **Reusability** - Skills can be used in other projects or contexts

## Key Principle

**Agents** = Workflow roles and decision-making
**Skills** = Reusable procedural knowledge

**Agent files should describe:**
- What the agent does
- When decisions are made
- What information is needed
- How to hand off work

**Skills should describe:**
- How to execute procedures
- What standards to follow
- What templates to use
- What best practices apply

---

## Next Steps

1. Complete editing of all 6 agent files
2. Test the workflow with a sample feature
3. Update CLAUDE.md if needed to reference skills
4. Document this migration for future reference
