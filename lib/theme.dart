import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Jetta tasarım dili — "Gece Otoyolu":
/// asfalt siyahı zeminler, tır farı amberi aksanlar, otoyol tabelası
/// tipografisi (Archivo) ve teknik veriler için mono (JetBrains Mono).
abstract final class JColors {
  static const bg = Color(0xFF0A0D12);
  static const surface = Color(0xFF11161D);
  static const surfaceHi = Color(0xFF1A212B);
  static const line = Color(0xFF242E3A);

  static const amber = Color(0xFFFFB23E);
  static const amberDeep = Color(0xFFE08900);

  static const text = Color(0xFFF2F5F8);
  static const textDim = Color(0xFF93A4B5);
  static const textFaint = Color(0xFF5A6B7C);

  static const green = Color(0xFF3DD68C);
  static const red = Color(0xFFFF6B6B);
  static const blue = Color(0xFF5CA8FF);
}

abstract final class JText {
  /// Büyük başlıklar — otoyol tabelası havası.
  static TextStyle display(double size, {Color color = JColors.text}) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle title(double size, {Color color = JColors.text}) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle body(double size,
          {Color color = JColors.text, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: weight,
        height: 1.4,
        color: color,
      );

  /// Plaka kodları, fiyatlar, tonaj — teknik mono.
  static TextStyle mono(double size,
          {Color color = JColors.text, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        height: 1.1,
        color: color,
      );

  /// Etiketler — geniş harf aralıklı, büyük harf.
  static TextStyle label(double size, {Color color = JColors.textDim}) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: color,
      );
}

ThemeData buildJettaTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: JColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: JColors.amber,
      onPrimary: Color(0xFF1A1102),
      secondary: JColors.blue,
      surface: JColors.surface,
      onSurface: JColors.text,
      error: JColors.red,
      outline: JColors.line,
    ),
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: GoogleFonts.archivoTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: JColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: JColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: JColors.line, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JColors.surfaceHi,
      hintStyle: JText.body(15, color: JColors.textFaint),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JColors.amber, width: 1.6),
      ),
    ),
  );
}
