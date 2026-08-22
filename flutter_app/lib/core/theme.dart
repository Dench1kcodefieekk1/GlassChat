import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 dark theme with the GlassChat glassmorphism palette.
class GlassTheme {
  static const Color seed = Color(0xFF3D7BFF);
  static const Color background = Color(0xFF0B0F17);
  static const Color surfaceGlass = Color(0x14FFFFFF);
  static const Color strokeGlass = Color(0x1FFFFFFF);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }
}
