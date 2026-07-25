import 'package:flutter/material.dart';

class AppColors {
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFA855F7);
  static const Color pink = Color(0xFFEC4899);
  static const Color pinkLight = Color(0xFFF472B6);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFF3E8FF), Color(0xFFFCE7F3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color background = Color(0xFFF8F7FF);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color sidebarBg = Color(0xFF1E1B4B);
  static const Color sidebarActive = Color(0xFF7C3AED);
}
