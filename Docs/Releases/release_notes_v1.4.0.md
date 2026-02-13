# FitTrack v1.4.0 Release Notes

**Release Date:** 2026-02-13
**Version:** 1.4.0+5
**Platforms:** Android, iOS

## What's New

### Workout Templates & Pre-built Programs

Never start from scratch again! FitTrack v1.4.0 introduces templates -- pre-built programs to get you training immediately, plus the ability to save your own workouts, weeks, and programs as reusable templates.

### Pre-built Program Templates

Get started faster with professionally designed workout programs:

- **Push Pull Legs** - Classic 6-day split for intermediate to advanced lifters
- **Upper/Lower Split** - Balanced 4-day program targeting upper and lower body
- **Full Body 3-Day** - Efficient whole-body training for beginners and busy schedules
- And more programs added regularly -- no app update required!

**How to use:** Programs > Create Program > From Template > Browse & Preview > Use Template

### Save Your Own Templates

Turn your best workouts into reusable templates:

- **Save any workout** as a template from the workout screen
- **Save entire weeks** with all their workouts and exercises
- **Save complete programs** to recreate your training blocks
- Store up to **10 templates per type** (workouts, weeks, programs)

**How to use:** Open any workout/week/program > Menu > Save as Template

### My Templates

Manage all your saved templates in one place:

- Access from **Profile > My Templates**
- Three organized sections: Workouts, Weeks, Programs
- Rename or delete templates anytime
- See template counts against your limits

### Smart Template Application

When you create from a template, FitTrack handles the details:

- Full structure is copied (weeks, workouts, exercises, sets)
- Tracking values (weight, distance) reset for fresh starts
- Smart naming prevents duplicate names
- Works offline with local caching

## Benefits

- **Save Time** - Stop recreating the same workouts week after week
- **Get Started Fast** - Pre-built programs designed by fitness professionals
- **Stay Organized** - Template library keeps your best routines accessible
- **Flexibility** - Mix pre-built and personal templates however you like
- **Offline Ready** - Templates work even without internet

## Bug Fixes

- Fixed permission error when creating programs from templates
- Fixed loading spinner getting stuck on first visit to template picker
- Improved data parsing reliability for template content

## Technical Improvements

### Templates Feature (#260)
- New template data models with nested denormalized structures for efficient reads
- TemplateProvider with real-time stream subscriptions and server-side caching
- Generic TemplatePickerScreen widget reusable across all template types
- Template preview bottom sheets with full structure breakdown
- Firestore security rules for per-user template collections
- Batched writes (450-op limit) for deep copy template application
- Safe number parsing and null-safe timestamp handling

### Code Quality
- All automated tests passing (Unit, Widget, Integration)
- Comprehensive error handling for template operations
- Reactive state management with Consumer pattern for loading states

## Known Issues

None at this time.

## Upgrade Notes

This update is fully backward compatible. Existing programs and workouts are not affected. The new Templates feature is entirely additive -- browse pre-built programs or save your own templates to get started.

---

**GitHub Issue:** [#260 - Workout Templates & Pre-built Programs](https://github.com/justbuildstuff-dev/Fitness-App/issues/260)
**Technical Design:** [Workout Templates Technical Design](https://github.com/justbuildstuff-dev/Fitness-App/blob/main/Docs/Technical_Designs/Workout_Templates_Technical_Design.md)

## Implementation Tasks Completed

- Task #314: Create template data models
- Task #315: Create template converters
- Task #316: Add template Firestore service methods
- Task #318: Add Firestore security rules for templates
- Task #319: Create pre-built programs seed data
- Task #320: Create template picker screen
- Task #321: Create template preview bottom sheet
- Task #322: Create save template dialog
- Task #323: Add "From Template" to create screens
- Task #324: Add "Save as Template" to detail screens
- Task #325: Create My Templates screen
- Task #328: Write widget tests for template UI components
- Hotfix #348: Template application permission fix (4 bugs resolved)
