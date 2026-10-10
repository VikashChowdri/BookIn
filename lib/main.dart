import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/globals.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BookExchangeApp());
}

class BookExchangeApp extends StatelessWidget {
  const BookExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeType>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, currentThemeType, _) {
        ThemeData theme;
        ThemeData darkTheme;
        ThemeMode themeMode;

        switch (currentThemeType) {
          case AppThemeType.student:
            theme = AppTheme.studentTheme;
            darkTheme = AppTheme.studentTheme;
            themeMode = ThemeMode.light;
            break;
          case AppThemeType.light:
            theme = AppTheme.lightTheme;
            darkTheme = AppTheme.lightTheme; // fallback
            themeMode = ThemeMode.light;
            break;
          case AppThemeType.dark:
            theme = AppTheme.darkTheme; // fallback
            darkTheme = AppTheme.darkTheme;
            themeMode = ThemeMode.dark;
            break;
          case AppThemeType.system:
          default:
            theme = AppTheme.lightTheme;
            darkTheme = AppTheme.darkTheme;
            themeMode = ThemeMode.system;
            break;
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: theme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          scaffoldMessengerKey: scaffoldMessengerKey,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}