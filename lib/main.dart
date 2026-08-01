import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';

void main() {
  runApp(const BookExchangeApp());
}

class BookExchangeApp extends StatelessWidget {
  const BookExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Book Exchange',

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),

        fontFamily: 'Poppins',

        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),

        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}