import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Deep midnight blue palette matching the reference UI
  static const Color background = Color(0xFF070D1E);
  static const Color backgroundDarker = Color(0xFF040812);
  static const Color cardSurface = Color(0xFF0D1B36);
  static const Color cardSurfaceLight = Color(0xFF14274E);
  
  // Neon and accent colors
  static const Color primaryBlue = Color(0xFF38BDF8);
  static const Color primaryAccent = Color(0xFF60A5FA);
  static const Color deepAccent = Color(0xFF2563EB);
  static const Color lightCardBlue = Color(0xFF7DD3FC);
  static const Color electricCyan = Color(0xFF06B6D4);
  
  // Status & Puja accent colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenLight = Color(0xFF34D399);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRose = Color(0xFFF43F5E);
  static const Color goldAccent = Color(0xFFFBBF24);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color accentEmerald = successGreen;
  static const Color scaffoldDark = background;

  // Glass card borders and subtle glow
  static const Color glassBorder = Color(0x2E60A5FA);
  static const Color glassBorderLight = Color(0x4093C5FD);
  static const Color glassFill = Color(0x1A1E293B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryAccent,
        surface: cardSurface,
        surfaceContainerHighest: cardSurfaceLight,
        error: dangerRose,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white70,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF70C1527),
        elevation: 16,
        shadowColor: Colors.black.withAlpha(200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: glassBorderLight, width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x8A070F1F),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
    );
  }

  // Gradients
  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3A8A),
      Color(0xFF0F172A),
      Color(0xFF090D16),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient lightBlueCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF38BDF8),
      Color(0xFF0284C7),
    ],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x2638BDF8),
      Color(0x0D1E293B),
    ],
  );

  static const LinearGradient accentGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF60A5FA),
      Color(0xFF3B82F6),
      Color(0xFF1D4ED8),
    ],
  );
}
