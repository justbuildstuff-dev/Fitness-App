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
              // ignore: deprecated_member_use
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Always use light theme'),
                value: ThemeMode.light,
                // ignore: deprecated_member_use
                groupValue: themeProvider.currentThemeMode,
                // ignore: deprecated_member_use
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              // ignore: deprecated_member_use
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Always use dark theme'),
                value: ThemeMode.dark,
                // ignore: deprecated_member_use
                groupValue: themeProvider.currentThemeMode,
                // ignore: deprecated_member_use
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
              // ignore: deprecated_member_use
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                subtitle: const Text('Use system theme setting'),
                value: ThemeMode.system,
                // ignore: deprecated_member_use
                groupValue: themeProvider.currentThemeMode,
                // ignore: deprecated_member_use
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
