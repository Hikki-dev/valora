import 'package:flutter/material.dart';
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
  // Brand Colors - Audit Specification
  static const Color surface0 = Color(0xFF09090B);
  static const Color surface1 = Color(0xFF111113);
  static const Color surface2 = Color(0xFF1E1E22);
  static const Color accentAmber = Color(0xFFF5A623);
  
  static const Color gainGreen = Color(0xFF4ADE80);
  static const Color lossRed = Color(0xFFF87171);
  
  static const Color textPrimary = Color(0xFFFAFAF9);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF52525B);

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: surface0,
      primaryColor: accentAmber,
      colorScheme: const ColorScheme.dark(
        primary: accentAmber,
        secondary: accentAmber,
        surface: surface1,
        surfaceContainer: surface2,
      ),
      hoverColor: accentAmber.withValues(alpha: 0.1),
      cardTheme: CardThemeData(
        color: surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'PlusJakartaSans',
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ).copyWith(
        displayLarge: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, color: textPrimary),
        displayMedium: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, color: textPrimary),
        displaySmall: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, color: textPrimary),
        headlineLarge: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: textPrimary),
        headlineSmall: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: textPrimary),
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
      scaffoldBackgroundColor: Colors.white,
      primaryColor: accentAmber,
      colorScheme: ColorScheme.light(
        primary: accentAmber,
        secondary: accentAmber,
        surface: Colors.grey.shade50,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'PlusJakartaSans',
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ).copyWith(
        displayLarge: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, color: Colors.black87),
        displayMedium: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, color: Colors.black87),
        displaySmall: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, color: Colors.black87),
        headlineLarge: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: Colors.black87),
        headlineMedium: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: Colors.black87),
        headlineSmall: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: Colors.black87),
        titleLarge: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: Colors.black87),
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
