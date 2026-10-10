import 'package:flutter/material.dart';

enum AppThemeType { system, light, dark, student }

/// Global controller to manage and notify app theme mode changes in real time.
class ThemeController {
  ThemeController._();

  /// Global ValueNotifier holding the current active ThemeMode.
  static final ValueNotifier<AppThemeType> themeModeNotifier =
      ValueNotifier<AppThemeType>(AppThemeType.light);

  /// Get current theme mode
  static AppThemeType get currentThemeType => themeModeNotifier.value;

  /// Update the current theme mode
  static void setThemeMode(AppThemeType type) {
    themeModeNotifier.value = type;
  }

  /// Toggle between light and dark mode
  static void toggleTheme(bool isDark) {
    themeModeNotifier.value = isDark ? AppThemeType.dark : AppThemeType.light;
  }

  /// Show a modern Theme Selection Dialog/Menu
  static void showThemeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<AppThemeType>(
          valueListenable: themeModeNotifier,
          builder: (context, currentMode, _) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.palette_outlined),
                  SizedBox(width: 10),
                  Text('Choose Theme'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ThemeOptionTile(
                    title: 'System Default',
                    icon: Icons.brightness_auto,
                    isSelected: currentMode == AppThemeType.system,
                    onTap: () {
                      setThemeMode(AppThemeType.system);
                      Navigator.pop(context);
                    },
                    primaryColor: theme.colorScheme.primary,
                  ),
                  _ThemeOptionTile(
                    title: 'Light Mode',
                    icon: Icons.light_mode_outlined,
                    isSelected: currentMode == AppThemeType.light,
                    onTap: () {
                      setThemeMode(AppThemeType.light);
                      Navigator.pop(context);
                    },
                    primaryColor: theme.colorScheme.primary,
                  ),
                  _ThemeOptionTile(
                    title: 'Dark Mode',
                    icon: Icons.dark_mode_outlined,
                    isSelected: currentMode == AppThemeType.dark,
                    onTap: () {
                      setThemeMode(AppThemeType.dark);
                      Navigator.pop(context);
                    },
                    primaryColor: theme.colorScheme.primary,
                  ),
                  _ThemeOptionTile(
                    title: 'Student Mode',
                    icon: Icons.school_outlined,
                    isSelected: currentMode == AppThemeType.student,
                    onTap: () {
                      setThemeMode(AppThemeType.student);
                      Navigator.pop(context);
                    },
                    primaryColor: const Color(0xFF6E8062), // Olive green
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: primaryColor)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: onTap,
    );
  }
}
