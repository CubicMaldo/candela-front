import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colours ─────────────────────────────────────────────────────────────────
const candelaAmber = Color(0xFFE8580A);
const candelaAmberLight = Color(0xFFF2780C);
const candelaNight = Color(0xFF1A1410);
const candelaSand = Color(0xFFFAF6F0);
const candelaSage = Color(0xFF5C8B6E);
const textSecondary = Color(0xFF6B5E58);
const borderInactive = Color(0xFFC4B8B2);
const textDarkPrimary = Color(0xFFFAF6F0);
const textDarkSecondary = Color(0xFF6B5E58);

/// Card/sheet surface used on the dark (Candela Night) theme. Shared so screens
/// don't re-hardcode the literal `0xFF2C2420`.
const surfaceDark = Color(0xFF2C2420);

/// Semantic colour for destructive actions (e.g. delete account, log out).
const candelaDanger = Color(0xFFB00020);

/// Semantic colour for warnings/attention (e.g. weak GPS signal). A warm amber
/// that stays in palette but reads distinct from the primary Candela Amber.
const candelaWarning = Color(0xFFE0922A);

// ─── Border radius ───────────────────────────────────────────────────────────
const radiusCard = 12.0;
const radiusMedium = 8.0;
const radiusPill = 20.0;

// ─── Spacing ─────────────────────────────────────────────────────────────────
const spacingScreen = 16.0;
const spacingCard = 16.0;
const spacingCardGap = 12.0;

/// Bottom inset that scrollable content must clear so nothing hides behind the
/// frosted tab bar + the raised central check-in button. Use as the bottom
/// padding of full-screen lists.
const kBottomGap = 96.0;

// ─── Typography ──────────────────────────────────────────────────────────────
TextTheme _candelaTextTheme(Color primary, Color secondary) {
  return TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: primary,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: primary,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: secondary,
    ),
    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: secondary,
    ),
  );
}

const _shapeCard = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(radiusCard)),
);

const _shapeBottomSheet = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
);

const _dialogTheme = DialogThemeData(elevation: 0, shape: _shapeCard);

/// iOS-style page transitions on every platform (slide + interactive
/// edge-swipe-back), so the app feels Cupertino while staying usable on Android.
const _pageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
  },
);

// ─── Themes ──────────────────────────────────────────────────────────────────
class CandleTheme {
  static ThemeData light() {
    const textPrimary = candelaNight;
    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: _pageTransitions,
      brightness: Brightness.light,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: candelaSand,
      colorScheme: const ColorScheme.light(
        primary: candelaAmber,
        secondary: candelaSage,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: _candelaTextTheme(textPrimary, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: candelaSand,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: _shapeCard,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: _shapeBottomSheet,
      ),
      dialogTheme: _dialogTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: _pageTransitions,
      brightness: Brightness.dark,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: candelaNight,
      colorScheme: const ColorScheme.dark(
        primary: candelaAmber,
        secondary: candelaSage,
        surface: surfaceDark,
        onPrimary: Colors.white,
        onSurface: textDarkPrimary,
      ),
      textTheme: _candelaTextTheme(textDarkPrimary, textDarkSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: candelaNight,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textDarkPrimary,
      ),
      cardTheme: const CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: _shapeCard,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: _shapeBottomSheet,
      ),
      dialogTheme: _dialogTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }
}

// ─── Derived tokens (alpha tints & shorthands) ───────────────────────────────
// Short aliases and tints derived from the canonical Candela palette above.
// The plain aliases map straight onto a base colour; the `kSoft*`/`kMuted`/
// `kBorder`/`kFaint` values are translucent tints used for chips, dividers and
// faint fills that have no opaque equivalent.
const kGreen = candelaSage;
const kBg = candelaSand;
const kField = Color(0xFFF4F0E9); // light input/field background
const kText = candelaNight;
const kMuted = Color(0x806B5E58); // textSecondary @ 50% — disabled/hint text
const kBorder = Color(0x1C1A1410); // night @ ~11% — hairline borders
const kFaint = Color(0x121A1410); // night @ ~7% — faint fills
const kSoftRed = Color(0x1AE8580A); // amber @ ~10% — soft accent fill
const kSoftGreen = Color(0x1F5C8B6E); // sage @ ~12% — success fill

TextStyle jakartaSans({
  double size = 16,
  FontWeight weight = FontWeight.w500,
  Color color = kText,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}
