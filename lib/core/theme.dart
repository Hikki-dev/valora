import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

class AppTheme {
  // Brand Colors - Liquid Glass Palette
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color darkObsidian = Color(0xFF0A0A0F);
  static const Color darkCard = Color(0xFF14141A);
  static const Color lightScaffold = Color(0xFFF8FAFC);
  static const Color lightCard = Colors.white;

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: darkObsidian,
      primaryColor: accentViolet,
      colorScheme: const ColorScheme.dark(
        primary: accentViolet,
        secondary: accentEmerald,
        surface: darkCard,
        surfaceContainer: Color(0xFF1A1A24),
      ),
      hoverColor: accentViolet.withValues(alpha: 0.1),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.syne(fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.syne(fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.syne(fontWeight: FontWeight.w800),
        headlineLarge: GoogleFonts.syne(fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.syne(fontWeight: FontWeight.w700),
        headlineSmall: GoogleFonts.syne(fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.syne(fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: lightScaffold,
      primaryColor: accentViolet,
      colorScheme: const ColorScheme.light(
        primary: accentViolet,
        secondary: accentEmerald,
        surface: lightCard,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.syne(fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.syne(fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.syne(fontWeight: FontWeight.w800),
        headlineLarge: GoogleFonts.syne(fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.syne(fontWeight: FontWeight.w700),
        headlineSmall: GoogleFonts.syne(fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.syne(fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }
}
