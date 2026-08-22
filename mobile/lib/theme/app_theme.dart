import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF087F6B);
  static const primaryDark = Color(0xFF075E54);
  static const navy = Color(0xFF16324F);
  static const accent = Color(0xFFE9B949);
  static const background = Color(0xFFF4F7F6);
  static const ink = Color(0xFF17252F);
  static const muted = Color(0xFF64747D);
}

ThemeData buildAppTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.navy,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.ink,
  );

  const radius = BorderRadius.all(Radius.circular(16));
  const fieldBorder = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: Color(0xFFDCE5E2)),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE4ECE9)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF8FAF9),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Color(0xFFBA1A1A), width: 1.6),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.primaryDark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: Color(0xFFCAD8D4)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE4ECE9)),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
