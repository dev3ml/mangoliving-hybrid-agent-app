import 'package:flutter/material.dart';

/// Brand tokens from the agent web dashboard (`mangoliving/agent/src/styles/theme.css`).
abstract final class AppColors {
  static const Color logo = Color(0xFFFE7D1B);
  static const Color primary = Color(0xFFF97316);
  static const Color primaryDark = Color(0xFFFB923C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF1F1206);

  static const Color accentWash = Color(0xFFFFF1E6);
  static const Color accentWashDark = Color(0xFF3A2410);

  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF171717);
  static const Color surfaceDark = Color(0xFF2E2E2E);

  static const Color ink = Color(0xFF171717);
  static const Color mutedWash = Color(0xFFF3F3F5);
  static const Color muted = Color(0xFF717182);
  static const Color mutedDark = Color(0xFFB4B4B4);

  static const Color destructive = Color(0xFFD4183D);
  static const Color divider = Color(0xFFD1D5DB);

  static const Color clients = Color(0xFF2563EB);
  static const Color pending = Color(0xFFD97706);
  static const Color showings = Color(0xFF7C3AED);
  static const Color messages = Color(0xFF059669);

  static const Color sharing = Color(0xFF059669);
  static const Color amberBanner = Color(0xFFFFFBEB);
  static const Color amberBorder = Color(0xFFFCD34D);
  static const Color attentionPurple = Color(0xFF7C3AED);
  static const Color followup = Color(0xFFEA580C);
  static const Color inquiry = Color(0xFF2563EB);
  static const Color showingAction = Color(0xFFDC2626);
  static const Color review = Color(0xFF16A34A);
  static const Color saved = Color(0xFFDB2777);

  static ColorScheme get lightColorScheme {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      error: destructive,
      surface: background,
    );
  }

  static ColorScheme get darkColorScheme {
    return ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      error: destructive,
      surface: backgroundDark,
    );
  }
}
