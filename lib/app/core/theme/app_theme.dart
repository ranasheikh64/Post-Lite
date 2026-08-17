import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Standard Dark Color Palette
  static const Color background = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF252526);
  static const Color surfaceHighlight = Color(0xFF333333);
  static const Color primary = Color(0xFFFF6C37); // Postman Orange
  static const Color primaryLight = Color(0xFFFF895D);
  static const Color secondary = Color(0xFF0EA5E9);
  
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF383838);

  // HTTP Method Colors
  static const Color getMethod = Color(0xFF0CBB52);
  static const Color postMethod = Color(0xFFFFB400);
  static const Color putMethod = Color(0xFF097BED);
  static const Color patchMethod = Color(0xFFF9A825);
  static const Color deleteMethod = Color(0xFFEB2013);

  static Color getMethodColor(String? method) {
    switch (method?.toUpperCase()) {
      case 'GET': return getMethod;
      case 'POST': return postMethod;
      case 'PUT': return putMethod;
      case 'PATCH': return patchMethod;
      case 'DELETE': return deleteMethod;
      default: return textSecondary;
    }
  }

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
