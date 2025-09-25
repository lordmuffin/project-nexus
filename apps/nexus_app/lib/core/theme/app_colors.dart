import 'package:flutter/material.dart';

/// Application color palette for Nexus
class AppColors {
  // Primary colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFF3B82F6);
  
  // Secondary colors
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color secondaryGreenDark = Color(0xFF059669);
  static const Color secondaryGreenLight = Color(0xFF34D399);
  
  // Neutral colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  
  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Surface colors
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1F1F1F);
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  static const Color surfaceVariantDark = Color(0xFF2D2D2D);
  
  // Text colors
  static const Color onSurface = neutral900;
  static const Color onSurfaceDark = neutral100;
  static const Color onSurfaceVariant = neutral600;
  static const Color onSurfaceVariantDark = neutral400;
  
  // Border colors
  static const Color border = neutral200;
  static const Color borderDark = neutral700;
  
  // Focus colors
  static const Color focus = primaryBlue;
  static const Color focusDark = primaryBlueLight;
}