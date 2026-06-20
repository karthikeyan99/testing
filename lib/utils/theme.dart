import 'package:flutter/material.dart';

/// Brand colours per marketplace, used across chips and charts.
class AppColors {
  static const flipkart = Color(0xFF2874F0);
  static const amazon = Color(0xFFFF9900);
  static const profit = Color(0xFF2E7D32);
  static const loss = Color(0xFFC62828);
  static const tax = Color(0xFF6A1B9A);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2874F0),
    brightness: Brightness.light,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      color: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
