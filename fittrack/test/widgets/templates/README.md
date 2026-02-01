# Template Widget Tests

This directory contains widget tests for the template UI components.

## Test Files to Create

Once the following PRs are merged to the feature branch, create widget tests:

1. **save_template_dialog_test.dart** (PR #337)
   - Test dialog displays correctly
   - Test name validation (required, min length)
   - Test description is optional
   - Test cancel dismisses without result
   - Test save returns SaveTemplateResult

2. **create_options_sheet_test.dart** (PR #338)
   - Test sheet displays correctly
   - Test "Start Fresh" option returns CreateOption.startFresh
   - Test "From Template" option returns CreateOption.fromTemplate
   - Test disabled state renders correctly

3. **save_as_template_menu_item_test.dart** (PR #339)
   - Test menu item renders correctly
   - Test SaveAsTemplateHelper handles dialog flow

4. **template_picker_screen_test.dart** (PR #335)
   - Test loading state
   - Test empty state
   - Test template list renders
   - Test source filter works
   - Test template selection

5. **template_preview_sheet_test.dart** (PR #336)
   - Test WorkoutTemplatePreviewSheet renders
   - Test WeekTemplatePreviewSheet renders
   - Test ProgramTemplatePreviewSheet renders
   - Test "Use Template" button works

6. **my_templates_screen_test.dart** (PR #340)
   - Test tabs display correctly
   - Test workout templates tab
   - Test week templates tab
   - Test program templates tab
   - Test delete confirmation
   - Test empty states

## Dependencies

All tests require TemplateProvider mock from:
`test/providers/template_provider_test.mocks.dart`

Run `dart run build_runner build` to generate mocks.
