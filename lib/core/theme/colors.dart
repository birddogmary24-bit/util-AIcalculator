import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── DT-522 Physical Calculator Palette ───────────────────────────────

  // Calculator button colors
  static const Color numBtn     = Color(0xFFDADCE2); // Bright gray number keys
  static const Color funcBtn    = Color(0xFFB4BFE0); // Bright blue function keys (+/-, %, ()
  static const Color clearBtn   = Color(0xFFE07800); // Deeper orange C/AC key
  static const Color operatorBtn = Color(0xFF2A2832); // Dark charcoal operator keys
  static const Color equalBtn   = Color(0xFF1E1C28); // Slightly darker for = key

  // These are kept for reference / other screens but not used on main calculator
  static const Color operator_  = Color(0xFF2A2832);
  static const Color operatorDark = Color(0xFF1A1820);
  static const Color numBtnDark  = Color(0xFF444444);
  static const Color funcBtnDark = Color(0xFF737373);

  // ── LCD Display ──────────────────────────────────────────────────────
  static const Color lcdBg      = Color(0xFFCDD8A4); // LCD greenish screen
  static const Color lcdText    = Color(0xFF1C2410); // Dark LCD digit color
  static const Color lcdExpr    = Color(0xFF4A5430); // Dim expression text (LCD)
  static const Color lcdBezel   = Color(0xFF18181E); // Dark outer bezel
  static const Color lcdCursor  = Color(0xFF2A3C18); // Blinking cursor color

  // ── App Body ─────────────────────────────────────────────────────────
  static const Color bodyBg     = Color(0xFFBEC2C8); // Silver calculator body
  static const Color bodyDark   = Color(0xFF9EA2A8); // Slightly darker for depth
  static const Color appBarBg   = Color(0xFF4A5882); // Indigo blue app bar

  // ── Legacy / Other screens ────────────────────────────────────────────
  static const Color displayBg      = Color(0xFF1C1C1E);
  static const Color displayBgLight = Color(0xFFCDD8A4); // reuse LCD color
  static const Color resultText     = Color(0xFF1C2410);
  static const Color resultTextLight = Color(0xFF1C2410);
  static const Color expressionText = Color(0xFF4A5430);

  // AI Tip Card
  static const Color aiTipBg      = Color(0xFFEEF2FF);
  static const Color aiTipBgLight = Color(0xFFEEF2FF);
  static const Color aiTipAccent  = Color(0xFF4A5882);

  // App primary (used for AI accents)
  static const Color primary      = Color(0xFF4A5882);
  static const Color primaryLight = Color(0xFF7A8AB2);

  // Status
  static const Color success = Color(0xFF34C759);
  static const Color error   = Color(0xFFFF3B30);

  // Neutral
  static const Color background   = Color(0xFFBEC2C8);
  static const Color darkBackground = Color(0xFF000000);
  static const Color surface      = Color(0xFFD0D4DA);
  static const Color darkSurface  = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6A6E7A);
  static const Color border       = Color(0xFFA0A4AA);
  static const Color darkBorder   = Color(0xFF38383A);
}
