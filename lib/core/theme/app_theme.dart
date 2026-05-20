import 'package:flutter/material.dart';

class AppTheme {
  // Brand Gradients & Backgrounds
  static const Color darkBgStart = Color(0xFFF8FAFC); // Clean Slate-50 Light Background
  static const Color darkBgEnd = Color(0xFFF1F5F9); // Slate-100
  static const Color cardColor = Color(0xFFFFFFFF); // Pure White
  static const Color sidebarColor = Color(0xFFFFFFFF); // Clean White Sidebar
  
  // Accents
  static const Color primary = Color(0xFF8B5CF6); // Coolmogo Violet
  static const Color secondary = Color(0xFFEC4899); // Coolmogo Coral/Pink
  static const Color textPrimary = Color(0xFF0F172A); // Zinc 900 (Dark Charcoal Text)
  static const Color textSecondary = Color(0xFF64748B); // Slate 500 (Muted Text)
  static const Color border = Color(0xFFE2E8F0); // Slate 200 (Clean Light Borders)

  // Status/Priority Colors
  static const Color statusTodo = Color(0xFF3B82F6);
  static const Color statusProgress = Color(0xFFF59E0B);
  static const Color statusDone = Color(0xFF10B981);
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);

  // Background Gradient Decoration
  static BoxDecoration get backgroundGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkBgStart, darkBgEnd],
        ),
      );

  // Glass Card Decoration
  static BoxDecoration glassCard({
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? const Color(0xFFFFFFFF).withOpacity(0.85),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: border ?? Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
    );
  }

  // Modern Text Styles
  static TextStyle get headingStyle => const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get subHeadingStyle => const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get captionStyle => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: textSecondary,
      );
}
