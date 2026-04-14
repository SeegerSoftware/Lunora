import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'colors.dart';
import 'spacing.dart';
import 'text_styles.dart';

/// Thème principal Lunora (nuit douce + violet pastel).
abstract final class LunoraTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: LunoraColors.violetSoft,
        onPrimary: LunoraColors.warmBeige,
        primaryContainer: LunoraColors.violetMuted,
        onPrimaryContainer: LunoraColors.warmBeige,
        secondary: LunoraColors.violetGlow,
        onSecondary: LunoraColors.nightBlue,
        tertiary: LunoraColors.starGold,
        onTertiary: LunoraColors.nightBlue,
        error: const Color(0xFFFF9A9A),
        onError: LunoraColors.nightBlue,
        surface: LunoraColors.nightBlueLift,
        onSurface: LunoraColors.warmBeige,
        onSurfaceVariant: LunoraColors.mist.withValues(alpha: 0.75),
        outline: LunoraColors.mist.withValues(alpha: 0.2),
        outlineVariant: LunoraColors.mist.withValues(alpha: 0.12),
        shadow: Colors.black.withValues(alpha: 0.35),
        scrim: Colors.black.withValues(alpha: 0.55),
        inverseSurface: LunoraColors.warmBeige,
        onInverseSurface: LunoraColors.nightBlue,
        inversePrimary: LunoraColors.violetMuted,
        surfaceContainerHighest: LunoraColors.nightBlueLift.withValues(
          alpha: 0.9,
        ),
      ),
      scaffoldBackgroundColor: LunoraColors.nightBlue,
      dividerColor: LunoraColors.mist.withValues(alpha: 0.1),
    );

    final textTheme = LunoraTextStyles.nunitoTextTheme(base.textTheme).apply(
      bodyColor: LunoraColors.warmBeige,
      displayColor: LunoraColors.warmBeige,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: LunoraColors.warmBeige,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: LunoraColors.warmBeige,
        ),
      ),
      cardTheme: CardThemeData(
        color: LunoraColors.nightBlueLift.withValues(alpha: 0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppSizes.cardRadius),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LunoraColors.warmBeige.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: LunoraColors.violetGlow,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LunoraSpacing.md,
          vertical: LunoraSpacing.sm + 2,
        ),
        hintStyle: TextStyle(color: LunoraColors.mist.withValues(alpha: 0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: LunoraSpacing.lg,
            vertical: LunoraSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: LunoraColors.violetSoft,
          foregroundColor: LunoraColors.warmBeige,
          shadowColor: LunoraColors.violetSoft.withValues(alpha: 0.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: LunoraSpacing.lg,
            vertical: LunoraSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: LunoraColors.violetSoft,
          foregroundColor: LunoraColors.warmBeige,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: LunoraSpacing.lg,
            vertical: LunoraSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
            color: LunoraColors.warmBeige.withValues(alpha: 0.28),
          ),
          foregroundColor: LunoraColors.warmBeige,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: LunoraColors.nightBlueLift,
        contentTextStyle: const TextStyle(color: LunoraColors.warmBeige),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get light => dark;
}
