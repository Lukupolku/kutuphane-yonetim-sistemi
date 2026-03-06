import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MEB brand colors — matches web dashboard (apps/web/src/index.css)
class MebColors {
  static const primary = Color(0xFF8B1A2B);
  static const primaryDark = Color(0xFF6E1422);
  static const primaryLight = Color(0xFFF5E6E9);
  static const accent = Color(0xFFA62639);
  static const sidebarDark = Color(0xFF2D1018);

  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F4F3);
  static const border = Color(0xFFE0DDD9);

  static const textPrimary = Color(0xFF1E1E20);
  static const textSecondary = Color(0xFF5A5A64);
  static const textTertiary = Color(0xFF8E8E9A);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFC42B2B);
}

ThemeData buildMebTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: MebColors.primary,
    primary: MebColors.primary,
    onPrimary: Colors.white,
    primaryContainer: MebColors.primaryLight,
    onPrimaryContainer: MebColors.primaryDark,
    secondary: MebColors.accent,
    onSecondary: Colors.white,
    surface: MebColors.surface,
    onSurface: MebColors.textPrimary,
    error: MebColors.error,
    onError: Colors.white,
  );

  final displayFont = GoogleFonts.outfitTextTheme();
  final bodyFont = GoogleFonts.nunitoTextTheme();

  final textTheme = TextTheme(
    displayLarge: displayFont.displayLarge,
    displayMedium: displayFont.displayMedium,
    displaySmall: displayFont.displaySmall,
    headlineLarge: displayFont.headlineLarge,
    headlineMedium: displayFont.headlineMedium,
    headlineSmall: displayFont.headlineSmall,
    titleLarge: displayFont.titleLarge,
    titleMedium: displayFont.titleMedium,
    titleSmall: displayFont.titleSmall,
    bodyLarge: bodyFont.bodyLarge,
    bodyMedium: bodyFont.bodyMedium,
    bodySmall: bodyFont.bodySmall,
    labelLarge: bodyFont.labelLarge,
    labelMedium: bodyFont.labelMedium,
    labelSmall: bodyFont.labelSmall,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: MebColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: MebColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MebColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MebColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MebColors.primary,
        side: const BorderSide(color: MebColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MebColors.primary,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: MebColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: MebColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: MebColors.border, width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: MebColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: MebColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: MebColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: MebColors.surface,
      labelStyle: const TextStyle(color: MebColors.textSecondary),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return MebColors.primary;
        }
        return null;
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: MebColors.border,
      thickness: 0.5,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: MebColors.sidebarDark,
      contentTextStyle: GoogleFonts.nunito(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: MebColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
