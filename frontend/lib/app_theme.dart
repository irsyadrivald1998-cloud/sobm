import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system: Industrial Futurist BMS
/// Based on DESIGN.md
class AppTheme {
  AppTheme._();

  // ── Colors ────────────────────────────────────────────────────────────────
  static const Color background         = Color(0xFF1E0F0E);
  static const Color surfaceLowest      = Color(0xFF180A09);
  static const Color surfaceLow        = Color(0xFF271816);
  static const Color surface           = Color(0xFF2C1B1A);
  static const Color surfaceHigh       = Color(0xFF372624);
  static const Color surfaceHighest    = Color(0xFF43302E);
  static const Color surfaceBright     = Color(0xFF473533);

  static const Color onSurface        = Color(0xFFF9DCD9);
  static const Color onSurfaceVariant = Color(0xFFE4BEBA);

  static const Color outline          = Color(0xFFAB8985);
  static const Color outlineVariant   = Color(0xFF5B403D);

  static const Color primary          = Color(0xFFFFB3AC);
  static const Color onPrimary        = Color(0xFF680008);
  static const Color primaryContainer = Color(0xFFD32F2F);
  static const Color onPrimaryContainer = Color(0xFFFFF2F0);
  static const Color primaryBrand     = Color(0xFFD32F2F); // solid brand red

  static const Color secondary        = Color(0xFFC8C6C5);
  static const Color onSecondary      = Color(0xFF303030);
  static const Color secondaryContainer = Color(0xFF474746);

  static const Color tertiary         = Color(0xFF7BD1F8);
  static const Color tertiaryContainer = Color(0xFF00799C);

  static const Color error            = Color(0xFFFFB4AB);
  static const Color errorContainer   = Color(0xFF93000A);

  static const Color alertCritical    = Color(0xFFF44336);

  // Functional status
  static const Color statusOk         = Color(0xFF4CAF50);
  static const Color statusWarning    = Color(0xFFFBBF24);
  static const Color statusError      = Color(0xFFD32F2F);

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
    color: onSurface,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: -0.01 * 24,
    color: onSurface,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: onSurface,
  );

  static const TextStyle titleLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: onSurface,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: onSurfaceVariant,
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.05 * 12,
    color: onSurfaceVariant,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.05 * 10,
    color: onSurfaceVariant,
  );

  // ── MaterialTheme ─────────────────────────────────────────────────────────
  static ThemeData get theme {
    // Base text theme with Inter via google_fonts
    final interTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      textTheme: interTextTheme,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        background: background,
        surface: surface,
        primary: primaryBrand,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        tertiary: tertiary,
        error: alertCritical,
        onError: Colors.white,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLowest,
        foregroundColor: onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: titleLg,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: outlineVariant, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: spSm),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spMd,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: primaryBrand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: alertCritical, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: alertCritical, width: 2),
        ),
        hintStyle: labelMd.copyWith(color: outline),
        labelStyle: labelMd,
        errorStyle: labelMd.copyWith(color: alertCritical),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: outlineVariant,
          disabledForegroundColor: outline,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spXl, vertical: spMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outlineVariant, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: spXl, vertical: spMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: bodyMd.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 0.5,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: outlineVariant, width: 0.5),
        ),
        titleTextStyle: headlineSm,
        contentTextStyle: bodyMd,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHighest,
        contentTextStyle: bodyMd.copyWith(color: onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaceLow),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              side: const BorderSide(color: outlineVariant),
            ),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryBrand;
          return surfaceHigh;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: outlineVariant, width: 1.5),
      ),
    );
  }
}
