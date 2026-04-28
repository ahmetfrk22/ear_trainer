import 'package:flutter/material.dart';

class AppTheme {
  static const Color kTeal = Color(0xFF008080);
  static const Color kOrange = Color(0xFFFFE0B2);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Playfair',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kTeal,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      iconTheme: const IconThemeData(color: Colors.white),
      textTheme: const TextTheme(
        bodySmall: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white70),
        bodyLarge: TextStyle(color: Colors.white70),
        labelSmall: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelLarge: TextStyle(color: Colors.white),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return const Color(0xFF7C6F9E);
          }),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFFA78BFA);
            }
            return const Color(0xFF1E1A2E);
          }),
        ),
      ),
    );
  }
}

