import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
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
            ],
          );
        },
      ),
    );
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
