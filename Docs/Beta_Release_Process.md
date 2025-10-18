# Beta Release Process

This document describes the process for creating and distributing beta builds to QA testers.

## Overview

Beta builds are created automatically via GitHub Actions and distributed to QA testers through Firebase App Distribution. Testers receive push notifications with download links when new builds are available.

## Beta Build Workflow

### 1. Complete Development Work
- Merge all PRs for the feature/fix to `main` branch
- Ensure all automated tests pass
- Verify code is production-ready

### 2. Prepare Release Notes

Edit `.github/BETA_RELEASE_TEMPLATE.md` with details about the build:

```markdown
## 📱 Beta Build - [Feature/Fix Name]

### Version
**Version:** 1.0.0-beta.YYYY-MM-DD

### What's New
✅ Feature/fix 1
✅ Feature/fix 2

### What to Test
- [ ] Test scenario 1
- [ ] Test scenario 2

### Known Issues
- None (or list any known issues)

### Related Issues
- Closes #XX
```

**Important:** Use clear, user-friendly language. QA testers are not developers!

### 3. Update Version Number (Optional but Recommended)

Update `fittrack/pubspec.yaml`:

```yaml
version: 1.0.0-beta.YYYY-MM-DD+BUILD_NUMBER
```

Where:
- `1.0.0` = Target production version
- `beta.YYYY-MM-DD` = Beta identifier with date
- `BUILD_NUMBER` = Incremental number (e.g., 1, 2, 3)

**Examples:**
- `1.0.0-beta.2025-10-13+1` - First beta of the day
- `1.0.0-beta.2025-10-13+2` - Second beta (bug fixes)
- `1.1.0-beta.2025-10-15+1` - First beta for v1.1.0

### 4. Trigger Beta Build

Add the `create-beta-build` label to the related GitHub issue:

```bash
gh issue edit <ISSUE_NUMBER> --add-label "create-beta-build"
```

**Example:**
```bash
gh issue edit 39 --add-label "create-beta-build"
```

### 5. Monitor Build Progress

The GitHub Actions workflow will:
1. ✅ Checkout latest `main` branch code
2. ✅ Read release notes from `BETA_RELEASE_TEMPLATE.md`
3. ✅ Build Android APK in release mode
4. ✅ Upload to Firebase App Distribution
5. ✅ Notify QA testers group
6. ✅ Comment on the GitHub issue
7. ✅ Remove `create-beta-build` label
8. ✅ Add `beta-build-ready` label

View progress at: https://github.com/justbuildstuff-dev/Fitness-App/actions

### 6. Clean Up Template (For Next Release)

After build completes, clear `.github/BETA_RELEASE_TEMPLATE.md` back to the empty template for the next release.

## Version Numbering Scheme

### Beta Versions
Use date-based versioning for beta builds:

**Format:** `MAJOR.MINOR.PATCH-beta.YYYY-MM-DD+BUILD`

**Examples:**
- `1.0.0-beta.2025-10-13+1` - First beta for Dark Mode features
- `1.0.0-beta.2025-10-13+2` - Bug fix beta same day
- `1.1.0-beta.2025-11-01+1` - First beta for Analytics v2 features

### Production Versions
Use semantic versioning for production releases:

**Format:** `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR:** Breaking changes (e.g., 1.0.0 → 2.0.0)
- **MINOR:** New features (e.g., 1.0.0 → 1.1.0)
- **PATCH:** Bug fixes (e.g., 1.0.1 → 1.0.2)
- **BUILD:** Incremental build number (e.g., +5, +6, +7)

**Examples:**
- `1.0.0+1` - First production release
- `1.0.1+2` - First bug fix release (build 2)
- `1.1.0+10` - Minor feature release (build 10)

## Release Notes Best Practices

### ✅ DO:
- Use clear, non-technical language
- Focus on user-visible changes
- Provide specific testing instructions
- List known issues upfront
- Use emojis for visual appeal (✅, 🐛, 🎨, ⚡)
- Group related changes together

### ❌ DON'T:
- Use technical jargon (refactoring, dependency injection, etc.)
- Include commit hashes or PR numbers (unless in "Related Issues")
- Write vague descriptions ("Fixed bugs", "Made improvements")
- Assume testers know implementation details
- Forget to list known issues

### Good Example:
```markdown
✅ **Fixed Error Messages** - No more technical jargon! Error messages are now user-friendly
```

### Bad Example:
```markdown
✅ Refactored ErrorDisplay widget and updated ProgramProvider error handling
```

## QA Tester View

Testers will see in Firebase App Distribution:

**Version:** 1.0.0-beta.2025-10-13+1

**Release Notes:**
```
📱 Beta Build - UI Consistency & Error Messaging

What's New:
✅ Fixed Error Messages - No more technical jargon!
✅ Brighter Analytics Colors - Easier to read in dark mode

What to Test:
- [ ] Check error messages are user-friendly
- [ ] Verify analytics colors in dark mode

Known Issues: None
```

This makes it crystal clear what changed and what to test!

## Firebase App Distribution

### QA Testers Group
Testers are added to the `qa-testers` group in Firebase console.

### Notifications
- Email notification sent when new build available
- Push notification on Android devices (if App Distribution app installed)
- Download link expires after 150 days

### Testing Instructions
Testers should:
1. Install latest beta from Firebase notification
2. Follow "What to Test" checklist in release notes
3. Report bugs as GitHub issues with `bug` label
4. Provide screenshots/videos for UI issues

## Troubleshooting

### Build Failed
- Check GitHub Actions logs for errors
- Verify `FIREBASE_APP_ID` and `FIREBASE_SERVICE_ACCOUNT` secrets are configured
- Ensure `main` branch builds locally with `flutter build apk --release`

### Testers Not Receiving Notifications
- Verify testers are in `qa-testers` group in Firebase console
- Check Firebase App Distribution settings
- Ask testers to check spam folder for email notifications

### Wrong Release Notes Showing
- Verify `BETA_RELEASE_TEMPLATE.md` was updated before triggering build
- Check workflow logs to see what notes were read
- Template must be committed to `main` branch before build

## Related Documentation
- [Agent-Driven Development Workflow](../CLAUDE.md#agent-driven-development-workflow)
- [GitHub Actions Configuration](../CLAUDE.md#github-actions)
- [Issue Labels](../CLAUDE.md#issue-labels)
