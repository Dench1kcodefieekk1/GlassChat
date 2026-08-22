import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme constants mirroring the iOS GlassChat palette.
class AppTheme {
  static const Color accent = Color(0xFF3D7BFF);
  static const Color background = Color(0xFF0B0F17);
  static const Color cardSurface = Color(0xFF161D2B);
  static const Color bubbleIncoming = Color(0xFF1B2230);
  static const Color online = Color(0xFF34C759);
  static const Color separator = Color(0x14FFFFFF);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: background,
      dividerColor: separator,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }
}
