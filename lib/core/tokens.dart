import 'package:flutter/material.dart';

/// "Midnight Manga" design tokens. Every colour has a tuned light and dark value
/// (gold can't be text on light, so prices there are ink on gold or dark amber).
/// Light is the default theme.
@immutable
class VTokens {
  final Color bg, surface, surface2, text, muted, line, soft;
  final Color money, onMoney, moneyText, accent, onAccent;
  final Color gainBg, gainInk, lossBg, lossInk;

  /// Red for destructive text/icons on a plain surface (lossInk is for text ON lossBg).
  final Color danger;
  final Color shadow, shadow2, dots, rays;

  const VTokens({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.muted,
    required this.line,
    required this.soft,
    required this.money,
    required this.onMoney,
    required this.moneyText,
    required this.accent,
    required this.onAccent,
    required this.gainBg,
    required this.gainInk,
    required this.lossBg,
    required this.lossInk,
    required this.danger,
    required this.shadow,
    required this.shadow2,
    required this.dots,
    required this.rays,
  });

  static const light = VTokens(
    bg: Color(0xFFF5F0E6),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEDE6D6),
    text: Color(0xFF15121F),
    muted: Color(0xFF5A5368),
    line: Color(0xFF15121F),
    soft: Color(0xFFD8CFBC),
    money: Color(0xFFFFC247),
    onMoney: Color(0xFF15121F),
    moneyText: Color(0xFF7A4E00),
    accent: Color(0xFFD81E5B),
    onAccent: Color(0xFFFFFFFF),
    gainBg: Color(0xFFCFF3DF),
    gainInk: Color(0xFF08592F),
    lossBg: Color(0xFFFBD9D5),
    lossInk: Color(0xFF8C1B14),
    danger: Color(0xFF8C1B14),
    shadow: Color(0xFF15121F),
    shadow2: Color(0xFF15121F),
    dots: Color(0x1715121F),
    rays: Color(0x0F15121F),
  );

  static const dark = VTokens(
    bg: Color(0xFF0B0A12),
    surface: Color(0xFF15131F),
    surface2: Color(0xFF1E1B2E),
    text: Color(0xFFF4EFE6),
    muted: Color(0xFFA9A3C0),
    line: Color(0xFFF4EFE6),
    soft: Color(0xFF2C2842),
    money: Color(0xFFFFC247),
    onMoney: Color(0xFF0B0A12),
    moneyText: Color(0xFFFFC247),
    accent: Color(0xFFFF5C8A),
    onAccent: Color(0xFF0B0A12),
    gainBg: Color(0xFF5EF2A0),
    gainInk: Color(0xFF0B0A12),
    lossBg: Color(0xFFFF7A7A),
    lossInk: Color(0xFF0B0A12),
    danger: Color(0xFFFF7A7A),
    shadow: Color(0xFFFFC247),
    shadow2: Color(0xFF2C2842),
    dots: Color(0x24FFC247),
    rays: Color(0x12F4EFE6),
  );

  static VTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Bundled font families (see pubspec.yaml).
class VFont {
  static const display = 'DelaGothicOne'; // numbers, titles
  static const body = 'ZenKakuGothicNew'; // everything else
  static const label = 'DotGothic16'; // eyebrow labels only
}

/// Ready-made text styles so screens stay consistent.
class VText {
  static TextStyle display(double size, Color color, {double? spacing}) =>
      TextStyle(
          fontFamily: VFont.display,
          fontSize: size,
          color: color,
          height: 1.1,
          letterSpacing: spacing);

  static TextStyle label(double size, Color color, {double spacing = 1.6}) =>
      TextStyle(
          fontFamily: VFont.label,
          fontSize: size,
          color: color,
          letterSpacing: spacing);

  static TextStyle body(double size, Color color,
          {FontWeight weight = FontWeight.w700}) =>
      TextStyle(
          fontFamily: VFont.body,
          fontSize: size,
          color: color,
          fontWeight: weight);
}
