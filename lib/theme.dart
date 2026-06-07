import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand colours ───────────────────────────────────────────────────────────
const kRed   = Color(0xFFE11D48);
const kGreen = Color(0xFF15B880);
const kBg    = Color(0xFFFFFFFF);
const kField = Color(0xFFF4F5F2);
const kText  = Color(0xFF14171A);
const kMuted = Color(0x8014171A); // 50 % alpha
const kBorder  = Color(0x1C14171A); // 11 % alpha
const kFaint   = Color(0x1214171A); //  7 % alpha
const kSoftRed   = Color(0x1AE11D48); // 10 % alpha
const kSoftGreen = Color(0x1F15B880); // 12 % alpha

// ─── Typography helper ────────────────────────────────────────────────────────
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

// ─── App theme ─────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData light() {
    return ThemeData(
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.light(
        primary: kRed,
        secondary: kGreen,
        surface: kBg,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: kBg,
        elevation: 0,
        foregroundColor: kText,
      ),
      inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
    );
  }
}
