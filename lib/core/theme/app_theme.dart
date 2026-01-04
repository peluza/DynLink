import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00E5FF), // Cyan Accent
        brightness: Brightness.dark,
        primary: const Color(0xFF00E5FF),
        secondary: const Color(0xFF2979FF),
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.outfitTextTheme(),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  // Common UI constants can also go here
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color dropdownColor = Color(0xFF2C2C2C);
}
