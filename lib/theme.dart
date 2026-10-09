import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0F1424);
  static const surface = Color(0xFF1A2135);
  static const surface2 = Color(0xFF242C44);
  static const line = Color(0xFF2E3754);
  static const ember = Color(0xFFFF7A45);
  static const rose = Color(0xFFFF4D6D);
  static const mint = Color(0xFF4FD1C5);
  static const text = Color(0xFFEEF1F8);
  static const muted = Color(0xFF8A93AB);
  static const slate = Color(0xFF4A5577);
}

const emberGradient = LinearGradient(
  colors: [AppColors.ember, AppColors.rose],
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
);

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.ember,
    onPrimary: Color(0xFF1B0E08),
    secondary: AppColors.mint,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.rose,
    outline: AppColors.line,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: Brightness.dark);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.text),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.ember.withAlpha(46),
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? AppColors.ember : AppColors.muted)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? AppColors.text : AppColors.muted)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ember, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.ember,
      foregroundColor: Color(0xFF1B0E08),
      extendedTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.ember.withAlpha(40) : AppColors.surface),
        foregroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.ember : AppColors.muted),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.line)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      dragHandleColor: AppColors.line,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surface2,
      contentTextStyle: const TextStyle(color: AppColors.text),
      actionTextColor: AppColors.ember,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
