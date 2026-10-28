import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ReflectMed AI Editorial Clinical Journal Brand Colors (Untitled (1).zip)
  static const Color primaryTeal = Color(0xFF0E5A60);
  static const Color primaryTealDark = Color(0xFF093E42);
  static const Color primaryTealLight = Color(0xFF167B83);
  static const Color darkTeal = Color(0xFF093E42);
  static const Color accentCyan = Color(0xFF4DB6AC);
  static const Color accentMint = Color(0xFF80CBC4);
  static const Color accentAmber = Color(0xFFB37D2E);
  static const Color medicalBlue = Color(0xFF3B5B88);

  // Background & Surface (Warm Parchment / Linen / Paper)
  static const Color lightBackground = Color(0xFFF5EFEB);
  static const Color parchmentBg = Color(0xFFF5EFEB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFFAF7F2);
  static const Color surfaceSand = Color(0xFFEBE4DA);
  static const Color lightBorder = Color(0xFFE0D7CC);
  static const Color darkBackground = Color(0xFF121817);
  static const Color darkSurface = Color(0xFF1B2423);

  // Text Colors (Ink Black & Muted Slate)
  static const Color textInk = Color(0xFF1C2725);
  static const Color textMuted = Color(0xFF5A6764);
  static const Color textLight = Color(0xFF8A9794);

  // 6 Gibbs Reflective Cycle Stage Colors (Untitled (1).zip)
  static const Color stageDeskripsi = Color(0xFF0E5A60);  // 01 Deskripsi (Deep Teal)
  static const Color stagePerasaan = Color(0xFF73568C);   // 02 Perasaan (Royal Purple)
  static const Color stageEvaluasi = Color(0xFFB37D2E);   // 03 Evaluasi (Ochre/Amber)
  static const Color stageAnalisis = Color(0xFFB85D3B);   // 04 Analisis (Terracotta)
  static const Color stageKesimpulan = Color(0xFF4F7348); // 05 Kesimpulan (Olive Green)
  static const Color stageRencana = Color(0xFF3B5B88);    // 06 Rencana Aksi (Slate Navy)

  // Clinical Specialty Colors
  static const Color catKardiologi = Color(0xFFB85D3B);
  static const Color catRespirasi = Color(0xFF4F7348);
  static const Color catEndokrin = Color(0xFF0E5A60);
  static const Color catNeuro = Color(0xFF73568C);
  static const Color catFarmakologi = Color(0xFF0E5A60);
  static const Color catKomunikasi = Color(0xFF73568C);
  static const Color catLain = Color(0xFFB37D2E);

  // Depth Level Colors (AMEE Guide 44)
  static const Color depthSuperficial = Color(0xFFB85D3B);
  static const Color depthAnalytical = Color(0xFFB37D2E);
  static const Color depthTransformative = Color(0xFF4F7348);

  // Typography Helpers (Serif Editorial + Clean Sans)
  static TextStyle serifTitle({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textInk,
    FontStyle fontStyle = FontStyle.normal,
    double? height,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      height: height,
    );
  }

  static TextStyle bodyText({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = textInk,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle metadata({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w700,
    Color color = textMuted,
    double letterSpacing = 1.4,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTeal,
      primary: primaryTeal,
      secondary: stagePerasaan,
      surface: surfaceWarm,
      background: lightBackground,
    ),
    scaffoldBackgroundColor: lightBackground,
    textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: textInk,
      displayColor: textInk,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBackground,
      foregroundColor: textInk,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.newsreader(
        color: textInk,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: textInk),
    ),
    cardTheme: CardThemeData(
      color: surfaceWarm,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTealLight,
      primary: primaryTealLight,
      secondary: accentCyan,
      surface: darkSurface,
      background: darkBackground,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: darkBackground,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
  );
}

