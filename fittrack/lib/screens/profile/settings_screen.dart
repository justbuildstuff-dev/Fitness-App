import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/weight_unit_provider.dart';
import '../../providers/exercise_library_provider.dart';
import '../../providers/template_provider.dart';
import 'my_exercises_screen.dart';
import 'my_templates_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Consumer2<ThemeProvider, WeightUnitProvider>(
        builder: (context, themeProvider, weightUnitProvider, child) {
          return ListView(
            children: [
              // Appearance Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Divider below Appearance heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 8),
              // Compact Theme Selector in Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Theme',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ThemeIconButton(
                            icon: Icons.brightness_auto,
                            label: 'System',
                            themeMode: ThemeMode.system,
                            currentThemeMode: themeProvider.currentThemeMode,
                            onPressed: () => themeProvider.setThemeMode(ThemeMode.system),
                          ),
                          const SizedBox(width: 8),
                          _ThemeIconButton(
                            icon: Icons.wb_sunny,
                            label: 'Light',
                            themeMode: ThemeMode.light,
                            currentThemeMode: themeProvider.currentThemeMode,
                            onPressed: () => themeProvider.setThemeMode(ThemeMode.light),
                          ),
                          const SizedBox(width: 8),
                          _ThemeIconButton(
                            icon: Icons.nights_stay,
                            label: 'Dark',
                            themeMode: ThemeMode.dark,
                            currentThemeMode: themeProvider.currentThemeMode,
                            onPressed: () => themeProvider.setThemeMode(ThemeMode.dark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Color Scheme Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Color Scheme',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Semantics(
                        label: 'Color scheme selector',
                        child: DropdownButton<ColorSchemeType>(
                          value: themeProvider.currentColorScheme,
                          underline: const SizedBox.shrink(),
                          borderRadius: BorderRadius.circular(12),
                          onChanged: (ColorSchemeType? newScheme) {
                            if (newScheme != null) {
                              themeProvider.setColorScheme(newScheme);
                            }
                          },
                          items: ColorSchemeType.values.map((scheme) {
                            return DropdownMenuItem<ColorSchemeType>(
                              value: scheme,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getColorForScheme(scheme),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_getDisplayNameForScheme(scheme)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Units Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Units',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weight Unit',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SegmentedButton<WeightUnit>(
                        segments: const [
                          ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                          ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                        ],
                        selected: {weightUnitProvider.unit},
                        onSelectionChanged: (selected) =>
                            weightUnitProvider.setUnit(selected.first),
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Exercise Library Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Exercise Library',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Divider below Exercise Library heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 8),
              // My Exercises Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Consumer<ExerciseLibraryProvider>(
                  builder: (context, provider, child) {
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                          child: Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                          ),
                        ),
                        title: const Text('My Exercises'),
                        subtitle: Text(
                          '${provider.customExerciseCount}/$maxCustomExercises custom exercises',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyExercisesScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // My Templates Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Consumer<TemplateProvider>(
                  builder: (context, provider, child) {
                    final totalTemplates = provider.workoutTemplateCount +
                        provider.weekTemplateCount +
                        provider.programTemplateCount;
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.dashboard_customize_outlined,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: const Text('My Templates'),
                        subtitle: Text(
                          '$totalTemplates saved templates',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyTemplatesScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getColorForScheme(ColorSchemeType scheme) {
    switch (scheme) {
      case ColorSchemeType.classicBlue:
        return const Color(0xFF2196F3);
      case ColorSchemeType.energeticOrange:
        return const Color(0xFFFF6B35);
      case ColorSchemeType.electricPurple:
        return const Color(0xFF7C3AED);
      case ColorSchemeType.crimsonPower:
        return const Color(0xFFDC143C);
    }
  }

  String _getDisplayNameForScheme(ColorSchemeType scheme) {
    switch (scheme) {
      case ColorSchemeType.classicBlue:
        return 'Classic Blue';
      case ColorSchemeType.energeticOrange:
        return 'Energetic Orange';
      case ColorSchemeType.electricPurple:
        return 'Electric Purple';
      case ColorSchemeType.crimsonPower:
        return 'Crimson Power';
    }
  }
}

class _ThemeIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeMode themeMode;
  final ThemeMode currentThemeMode;
  final VoidCallback onPressed;

  const _ThemeIconButton({
    required this.icon,
    required this.label,
    required this.themeMode,
    required this.currentThemeMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = themeMode == currentThemeMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '$label theme',
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
      ),
    );
  }
}
