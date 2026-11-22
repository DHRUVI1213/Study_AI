import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = true;

  static Color get background => isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF8FAFC);
  static Color get surface => isDark ? const Color(0xFF131929) : Colors.white;
  static Color get surfaceLight => isDark ? const Color(0xFF1C2438) : const Color(0xFFF1F5F9);
  static Color get card => isDark ? const Color(0xFF1A2235) : Colors.white;
  static Color get cardBorder => isDark ? const Color(0xFF2A3550) : const Color(0xFFE2E8F0);

  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color accent = Color(0xFF14B8A6);
  static const Color accentPink = Color(0xFFF472B6);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  static Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  static Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );

  static LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: isDark
        ? [const Color(0xFF0F172A), const Color(0xFF0B0F1A)]
        : [const Color(0xFFEDF2F7), const Color(0xFFF8FAFC)],
  );
}
