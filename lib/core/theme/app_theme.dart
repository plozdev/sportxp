import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF07080A);
  static const surface = Color(0xFF111317);
  static const border = Color(0xFF1B1F26);
  static const primary = Color(0xFF00D665);
  static const text = Color(0xFFFFFFFF);
  static const muted = Color(0xFF7E8695);
  static const loss = Color(0xFFE03131);
  static const streak = Color(0xFFF5A623);
}

abstract final class AppTokens {
  static const radius = 20.0;
  static const touchTarget = 48.0;
  static const contentWidth = 720.0;
  static const metric = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const label = TextStyle(fontSize: 12, color: AppColors.muted);
}

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.loss,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.border,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, AppTokens.touchTarget),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: AppColors.surface,
    ),
  );
}
