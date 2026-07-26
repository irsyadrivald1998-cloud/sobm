import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system: Clean Modern BMS
/// Updated to match login page color palette
class AppTheme {
  AppTheme._();

  // ── Dark Colors ───────────────────────────────────────────────────────────
  static const Color _darkBackground         = Color(0xFF0F0F14);
  static const Color _darkSurfaceLowest      = Color(0xFF0A0A0F);
  static const Color _darkSurfaceLow        = Color(0xFF16161E);
  static const Color _darkSurface           = Color(0xFF1C1C26);
  static const Color _darkSurfaceHigh       = Color(0xFF252530);
  static const Color _darkSurfaceHighest    = Color(0xFF2E2E3A);
  static const Color _darkSurfaceBright     = Color(0xFF363642);
  static const Color _darkOnSurface        = Color(0xFFF0F0F5);
  static const Color _darkOnSurfaceVariant = Color(0xFFB0B0C0);
  static const Color _darkOutline          = Color(0xFF7A7A8E);
  static const Color _darkOutlineVariant   = Color(0xFF3A3A48);

  // ── Light Colors ──────────────────────────────────────────────────────────
  static const Color _lightBackground       = Color(0xFFF5F5F8);
  static const Color _lightSurface          = Color(0xFFFFFFFF);
  static const Color _lightSurfaceLow       = Color(0xFFF8F8FA);
  static const Color _lightSurfaceHigh      = Color(0xFFF0F0F5);
  static const Color _lightOnSurface        = Color(0xFF1A1A2E);
  static const Color _lightOnSurfaceVariant = Color(0xFF5A5A6E);
  static const Color _lightOutline          = Color(0xFF7A7A8E);
  static const Color _lightOutlineVariant   = Color(0xFFE8E8EE);

  // ── Static Colors (same for both themes) ──────────────────────────────────
  static const Color primary          = Color(0xFFFF6B6B);
  static const Color onPrimary        = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFFDAD7);
  static const Color onPrimaryContainer = Color(0xFF410003);
  static const Color primaryBrand     = Color(0xFFD32F2F);

  static const Color secondary        = Color(0xFFB0B0C0);
  static const Color onSecondary      = Color(0xFF1A1A2E);
  static const Color secondaryContainer = Color(0xFF3A3A48);

  static const Color tertiary         = Color(0xFF7BD1F8);
  static const Color tertiaryContainer = Color(0xFF00799C);

  static const Color error            = Color(0xFFFFB4AB);
  static const Color errorContainer   = Color(0xFF93000A);
  static const Color alertCritical    = Color(0xFFD32F2F);

  static const Color statusOk         = Color(0xFF4CAF50);
  static const Color statusWarning    = Color(0xFFFBBF24);
  static const Color statusError      = Color(0xFFD32F2F);

  // ── Color Constants (Mapped to Light Mode for clean light UI) ────────────
  static const Color background         = _lightBackground;
  static const Color surfaceLowest      = _lightSurfaceHigh;
  static const Color surfaceLow        = _lightSurfaceLow;
  static const Color surface           = _lightSurface;
  static const Color surfaceHigh       = _lightSurfaceHigh;
  static const Color surfaceHighest    = Color(0xFFE8E8EE);
  static const Color surfaceBright     = _lightSurface;
  static const Color onSurface        = _lightOnSurface;
  static const Color onSurfaceVariant = _lightOnSurfaceVariant;
  static const Color outline          = _lightOutline;
  static const Color outlineVariant   = _lightOutlineVariant;

  // ── Public Light Colors ──────────────────────────────────────────────────
  static const Color lightBackground       = _lightBackground;
  static const Color lightSurface          = _lightSurface;
  static const Color lightSurfaceLow       = _lightSurfaceLow;
  static const Color lightSurfaceHigh      = _lightSurfaceHigh;
  static const Color lightOnSurface        = _lightOnSurface;
  static const Color lightOnSurfaceVariant = _lightOnSurfaceVariant;
  static const Color lightOutline          = _lightOutline;
  static const Color lightOutlineVariant   = _lightOutlineVariant;

  // ── Radii ─────────────────────────────────────────────────────────────────
  static const double radiusSm  = 8;
  static const double radiusMd  = 12;
  static const double radiusLg  = 16; // Standard for cards / inputs / buttons
  static const double radiusXl  = 24;
  static const double radiusFull = 9999;

  // ── Spacing (8px grid) ───────────────────────────────────────────────────
  static const double spXs  = 4;
  static const double spSm  = 8;
  static const double spMd  = 16;
  static const double spLg  = 24;
  static const double spXl  = 32;

  // ── Typography ───────────────────────────────────────────────────────────
  static const String fontFamily = 'Inter';

  // Use GoogleFonts.inter() to load Inter from google_fonts package.
  // Static TextStyle constants use the fallback family name;
  // use interStyle() below in widgets that need the live font.
  static TextStyle interStyle(TextStyle base) =>
      GoogleFonts.inter(textStyle: base);

  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.02 * 32,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: -0.01 * 24,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.05 * 12,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.05 * 10,
  );

  // ── MaterialTheme ─────────────────────────────────────────────────────────
  static ThemeData get theme => darkTheme;

  static ThemeData get darkTheme {
    final interTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: _darkOnSurface, displayColor: _darkOnSurface);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      textTheme: interTextTheme,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        surface: _darkSurface,
        primary: primaryBrand,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        tertiary: tertiary,
        error: alertCritical,
        onError: Colors.white,
        onSurface: _darkOnSurface,
        onSurfaceVariant: _darkOnSurfaceVariant,
        outline: _darkOutline,
        outlineVariant: _darkOutlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurfaceLowest,
        foregroundColor: _darkOnSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: titleLg,
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: _darkOutlineVariant, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: spSm),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: spMd, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: _darkOutlineVariant, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: primaryBrand, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: alertCritical, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: alertCritical, width: 2)),
        hintStyle: labelMd.copyWith(color: _darkOutline),
        labelStyle: labelMd.copyWith(color: _darkOnSurfaceVariant),
        prefixIconColor: _darkOnSurfaceVariant,
        suffixIconColor: _darkOnSurfaceVariant,
        errorStyle: labelMd.copyWith(color: alertCritical),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrand, foregroundColor: Colors.white,
          disabledBackgroundColor: _darkOutlineVariant, disabledForegroundColor: _darkOutline,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spXl, vertical: spMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkOnSurface,
          side: const BorderSide(color: _darkOutlineVariant, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: spXl, vertical: spMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary, textStyle: bodyMd.copyWith(fontWeight: FontWeight.w500)),
      ),
      dividerTheme: const DividerThemeData(color: _darkOutlineVariant, thickness: 0.5, space: 0),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurfaceLow, surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg), side: const BorderSide(color: _darkOutlineVariant, width: 0.5)),
        titleTextStyle: headlineSm, contentTextStyle: bodyMd,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurfaceHighest, contentTextStyle: bodyMd.copyWith(color: _darkOnSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(_darkSurfaceLow),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd), side: const BorderSide(color: _darkOutlineVariant))),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primaryBrand : _darkSurfaceHigh),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: _darkOutlineVariant, width: 1.5),
      ),
    );
  }

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final interTextTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    ).apply(bodyColor: _lightOnSurface, displayColor: _lightOnSurface);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      textTheme: interTextTheme,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        surface: _lightSurface,
        primary: primaryBrand,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFDAD7),
        onPrimaryContainer: Color(0xFF410003),
        secondary: Color(0xFF5A5A6E),
        onSecondary: Colors.white,
        tertiary: Color(0xFF006686),
        onTertiary: Colors.white,
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        onSurface: _lightOnSurface,
        onSurfaceVariant: _lightOnSurfaceVariant,
        outline: _lightOutline,
        outlineVariant: _lightOutlineVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurface,
        foregroundColor: _lightOnSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: _lightOutlineVariant.withValues(alpha: 0.3),
        titleTextStyle: titleLg.copyWith(color: _lightOnSurface),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: _lightOutlineVariant, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: spSm),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurfaceLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: spMd, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: _lightOutlineVariant, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: primaryBrand, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: alertCritical, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: alertCritical, width: 2)),
        hintStyle: labelMd.copyWith(color: const Color(0xFF9999AA)),
        labelStyle: labelMd.copyWith(color: _lightOnSurfaceVariant),
        prefixIconColor: _lightOnSurfaceVariant,
        suffixIconColor: _lightOnSurfaceVariant,
        errorStyle: labelMd.copyWith(color: alertCritical),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrand, foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spXl, vertical: spMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightOnSurface,
          side: const BorderSide(color: _lightOutlineVariant, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: spXl, vertical: spMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryBrand),
      ),
      dividerTheme: const DividerThemeData(color: _lightOutlineVariant, thickness: 0.5, space: 0),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface, surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg), side: const BorderSide(color: _lightOutlineVariant, width: 0.5)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightOnSurface,
        contentTextStyle: bodyMd.copyWith(color: _lightBackground),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primaryBrand : _lightSurfaceHigh),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: _lightOutlineVariant, width: 1.5),
      ),
    );
  }
}
