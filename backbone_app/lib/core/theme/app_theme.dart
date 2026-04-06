import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primary = Color(0xFF00C2FF);   // electric blue
  static const _surface = Color(0xFF0F0F1A);   // near-black
  static const _card    = Color(0xFF1A1A2E);
  static const _onSurface = Color(0xFFE8E8F0);

  // Entry type colors
  static const colorShow       = Color(0xFF00C2FF);
  static const colorTravel     = Color(0xFFFFB347);
  static const colorBlackedOut = Color(0xFF444455);
  static const colorFree       = Colors.transparent;

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _primary,
      surface: _surface,
      onSurface: _onSurface,
    ),
    scaffoldBackgroundColor: _surface,
    cardColor: _card,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: _surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: _onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _card,
      indicatorColor: _primary.withOpacity(0.15),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.inter(fontSize: 12, color: _onSurface),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
  );
}
