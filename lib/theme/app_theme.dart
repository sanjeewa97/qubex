import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color secondary = Color(0xFF0F172A); // Slate 900
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color accent = Color(0xFFF59E0B); // Amber 500 (For IQ/Points)
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, background: background),
      fontFamily: 'Roboto', // Default, assumes you will add custom fonts later
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: secondary),
        titleTextStyle: TextStyle(
          color: secondary, 
          fontSize: 20, 
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5
        ),
      ),
    );
  }
}
