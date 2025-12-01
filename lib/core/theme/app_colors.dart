import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFFD56F);
  static const Color primaryLight = Color(0xFFFFF3B0);
  static const Color primaryDark = Color(0xFFFFB84D);
  static const Color secondary = Color(0xFFFFA500);
  static const Color accent = Color(0xFFFFC107);

  static const Color background = Color(0xFFFFF9E6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFBF0);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surfaceLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 10,
      offset: Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 15,
      offset: Offset(0, 5),
    ),
  ];
}
