import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF0057B8);
  static const Color primaryTeal = Color(0xFF00C9A7);
  static const Color backgroundLight = Color(0xFFF5F9FF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color errorRed = Color(0xFFEF4444);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryTeal,
      surface: surfaceWhite,
      error: errorRed,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryTeal, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0F1620),
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryTeal,
      surface: Color(0xFF1A2332),
      error: errorRed,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          displayLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFFA0AEC0),
          ),
        ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A2332),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D3748)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryTeal, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A2332),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
