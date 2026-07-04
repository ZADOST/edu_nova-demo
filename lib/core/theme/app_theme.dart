import 'package:flutter/material.dart';

class AppTheme {
  static const Color mintGlow = Color(0xFF4DE2B3);
  static const Color deepTeal = Color(0xFF0B4135);
  static const Color darkCharcoal = Color(0xFF081412);
  static const Color pureWhite = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkCharcoal,
      primaryColor: mintGlow,
      fontFamily: 'Roboto', // Replace with your preferred font
      colorScheme: const ColorScheme.dark(
        primary: mintGlow,
        secondary: deepTeal,
        surface: darkCharcoal,
        error: Colors.redAccent,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: pureWhite, fontSize: 32, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: mintGlow, fontSize: 24, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: pureWhite, fontSize: 16),
        bodyMedium: TextStyle(color: pureWhite, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mintGlow,
          foregroundColor: darkCharcoal,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: mintGlow),
        titleTextStyle: TextStyle(color: pureWhite, fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }
}