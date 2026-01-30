/// Template models for Workout Templates & Pre-built Programs feature.
///
/// This library exports all template-related models for convenient importing.
///
/// Structure (bottom-up, nested to top-level):
/// - [TemplateSet] - Set configuration within an exercise
/// - [TemplateExercise] - Exercise with sets
/// - [TemplateWorkout] - Workout with exercises
/// - [TemplateWeek] - Week with workouts (nested structure for program templates)
/// - [WorkoutTemplate] - Top-level user/pre-built workout template
/// - [WeekTemplate] - Top-level user/pre-built week template
/// - [ProgramTemplate] - Top-level user/pre-built program template
library templates;

export 'template_set.dart';
export 'template_exercise.dart';
export 'template_workout.dart';
export 'template_week.dart';
export 'workout_template.dart';
export 'week_template.dart';
export 'program_template.dart';
