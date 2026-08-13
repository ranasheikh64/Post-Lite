import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Dark Color Palette
  static const Color background = Color(0xFF0D0E15); // Deep dark blue/black
  static const Color surface = Color(0xFF161822); // Slightly lighter for panels
  static const Color surfaceHighlight = Color(0xFF202332);
  static const Color primary = Color(0xFF7C3AED); // Vibrant Purple
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color divider = Color(0xFF2A2D3E);

  // HTTP Method Colors
  static const Color getMethod = Color(0xFF10B981); // Emerald
  static const Color postMethod = Color(0xFFF59E0B); // Amber
  static const Color putMethod = Color(0xFF3B82F6); // Blue
  static const Color patchMethod = Color(0xFF8B5CF6); // Purple
  static const Color deleteMethod = Color(0xFFEF4444); // Red

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: const TextStyle(color: textPrimary),
        bodyMedium: const TextStyle(color: textSecondary),
      ),
      cardColor: surface,
      dividerColor: divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHighlight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
        ),
      ),
    );
  }
}
