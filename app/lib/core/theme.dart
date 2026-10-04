import 'package:flutter/material.dart';

/// Palette originale (aucune couleur ni logo de marque officielle).
class AppColors {
  static const background = Color(0xFF0D0E12);
  static const surface = Color(0xFF16181F);
  static const surfaceHigh = Color(0xFF1F222B);
  static const outline = Color(0xFF2C303B);
  static const gold = Color(0xFFE8B04A);
  static const crimson = Color(0xFFD7263D);
  static const steel = Color(0xFF9AA4B2);
  static const text = Color(0xFFF2F3F5);
  static const textMuted = Color(0xFFA0A6B1);
  static const success = Color(0xFF3FB97F);
  static const warning = Color(0xFFE5A23B);

  /// Couleur associée à chaque niveau de rareté (lueurs, badges).
  static const rarity = {
    'commune': Color(0xFFB8BEC8),
    'peu_commune': Color(0xFF7FB3D5),
    'rare': Color(0xFF4F8DFF),
    'epique': Color(0xFFB45CFF),
    'legendaire': Color(0xFFE8B04A),
    'mythique': Color(0xFFFF4D6D),
  };
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.gold,
    onPrimary: Colors.black,
    secondary: AppColors.crimson,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.crimson,
    outline: AppColors.outline,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    brightness: Brightness.dark,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: Color(0x33E8B04A),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceHigh,
      side: const BorderSide(color: AppColors.outline),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
  );
}
