import 'package:flutter/material.dart';

/// Design tokens for Purohit Marketplace.
///
/// The layout language is borrowed from Upwork — dense scannable job cards, a
/// persistent search bar, chip filters, a single accent colour used sparingly
/// for primary actions. The palette is not: saffron and deep maroon read as
/// ceremonial without tipping into kitsch.
abstract final class AppColors {
  static const saffron = Color(0xFFD4741A);
  static const saffronDark = Color(0xFFA85610);
  static const maroon = Color(0xFF8C2F1E);
  static const marigold = Color(0xFFF2A93B);

  static const ink = Color(0xFF1C1917);
  static const inkMuted = Color(0xFF6B6560);
  static const inkFaint = Color(0xFF9C948C);

  static const surface = Color(0xFFFFFBF5);
  static const card = Colors.white;
  static const hairline = Color(0xFFE8E1D9);

  static const success = Color(0xFF2E7D46);
  static const warning = Color(0xFFB4690E);
  static const danger = Color(0xFFB3261E);

  /// Low-saturation washes for banners, selected chips and status pills.
  /// Tinting a surface reads as calmer than colouring the text alone.
  static const saffronTint = Color(0xFFFDF2E4);
  static const successTint = Color(0xFFEAF4ED);
  static const warningTint = Color(0xFFFDF3E2);
  static const dangerTint = Color(0xFFFBEBE9);
}

/// Motion scale. Short and consistent beats bespoke per-widget timings.
abstract final class AppDuration {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 360);
}

/// Spacing scale. Use these instead of magic numbers so screens stay aligned.
abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const card = 14.0;
  static const chip = 999.0;
  static const field = 12.0;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.saffron,
    primary: AppColors.saffron,
    secondary: AppColors.maroon,
    surface: AppColors.surface,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    dividerColor: AppColors.hairline,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.hairline),
      ),
    ),
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      },
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
      space: 1,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.saffron,
      selectionColor: AppColors.marigold.withValues(alpha: 0.35),
      selectionHandleColor: AppColors.saffron,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.saffron,
      linearMinHeight: 3,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.inkMuted,
      textColor: AppColors.ink,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: AppColors.marigold,
      insetPadding: const EdgeInsets.all(Gap.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.saffronTint,
      checkmarkColor: AppColors.saffronDark,
      side: const BorderSide(color: AppColors.hairline),
      labelStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Gap.lg,
        vertical: Gap.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.saffron, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: AppColors.hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.marigold.withValues(alpha: 0.28),
      elevation: 0,
      height: 66,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
