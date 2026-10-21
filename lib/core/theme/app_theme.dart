import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF2F7F3);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDFE9E1);
  static const primary = Color(0xFF176344);
  static const accent = Color(0xFF299A63);
  static const onPrimary = Color(0xFFFFFFFF);
  static const mint = Color(0xFFDDF2E3);
  static const text = Color(0xFF14251D);
  static const muted = Color(0xFF61736A);
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF176344), Color(0xFF299A63)],
  );
  static const loss = Color(0xFFBE123C);
  static const streak = Color(0xFF946200);
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
  // Compatibility for existing previews; the product now uses the light theme.
  static ThemeData get dark => light;
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.mint,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.primary,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.mint,
      onSecondaryContainer: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.muted,
      outlineVariant: AppColors.border,
      error: AppColors.loss,
    ),
    hintColor: AppColors.muted,
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.mint
              : AppColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.mint,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 2,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, AppTokens.touchTarget),
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppColors.border),
      ),
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: TextStyle(
        color: AppColors.muted,
        fontWeight: FontWeight.normal,
      ),
    ),
  );
}
