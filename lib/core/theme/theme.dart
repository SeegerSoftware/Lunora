import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'colors.dart';
import 'spacing.dart';
import 'text_styles.dart';

/// Thème principal Elunai (nuit douce + violet pastel).
abstract final class ElunaiTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: ElunaiColors.violetSoft,
        onPrimary: ElunaiColors.warmBeige,
        primaryContainer: ElunaiColors.violetMuted,
        onPrimaryContainer: ElunaiColors.warmBeige,
        secondary: ElunaiColors.violetGlow,
        onSecondary: ElunaiColors.nightBlue,
        tertiary: ElunaiColors.joySun,
        onTertiary: ElunaiColors.nightBlueDeep,
        error: const Color(0xFFFF9A9A),
        onError: ElunaiColors.nightBlue,
        surface: ElunaiColors.nightBlueLift,
        onSurface: ElunaiColors.warmBeige,
        onSurfaceVariant: ElunaiColors.mist.withValues(alpha: 0.75),
        outline: ElunaiColors.mist.withValues(alpha: 0.2),
        outlineVariant: ElunaiColors.mist.withValues(alpha: 0.12),
        shadow: Colors.black.withValues(alpha: 0.35),
        scrim: Colors.black.withValues(alpha: 0.55),
        inverseSurface: ElunaiColors.warmBeige,
        onInverseSurface: ElunaiColors.nightBlue,
        inversePrimary: ElunaiColors.violetMuted,
        surfaceContainerHighest: ElunaiColors.nightBlueLift.withValues(
          alpha: 0.9,
        ),
      ),
      scaffoldBackgroundColor: ElunaiColors.nightBlue,
      dividerColor: ElunaiColors.mist.withValues(alpha: 0.1),
    );

    final textTheme = ElunaiTextStyles.nunitoTextTheme(base.textTheme).apply(
      bodyColor: ElunaiColors.warmBeige,
      displayColor: ElunaiColors.warmBeige,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: ElunaiColors.warmBeige,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: ElunaiColors.warmBeige,
        ),
      ),
      cardTheme: CardThemeData(
        color: ElunaiColors.nightBlueLift.withValues(alpha: 0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppSizes.cardRadius),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ElunaiColors.warmBeige.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: ElunaiColors.violetGlow,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ElunaiSpacing.md,
          vertical: ElunaiSpacing.sm + 2,
        ),
        hintStyle: TextStyle(color: ElunaiColors.mist.withValues(alpha: 0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ElunaiSpacing.lg,
            vertical: ElunaiSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: ElunaiColors.violetSoft,
          foregroundColor: ElunaiColors.warmBeige,
          shadowColor: ElunaiColors.violetSoft.withValues(alpha: 0.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ElunaiSpacing.lg,
            vertical: ElunaiSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: ElunaiColors.violetSoft,
          foregroundColor: ElunaiColors.warmBeige,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: ElunaiSpacing.lg,
            vertical: ElunaiSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
            color: ElunaiColors.warmBeige.withValues(alpha: 0.28),
          ),
          foregroundColor: ElunaiColors.warmBeige,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ElunaiColors.nightBlueLift,
        contentTextStyle: const TextStyle(color: ElunaiColors.warmBeige),
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

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: ElunaiColors.forestGreen,
        onPrimary: ElunaiColors.storybookCream,
        primaryContainer: ElunaiColors.forestGreenSoft,
        onPrimaryContainer: ElunaiColors.storybookCream,
        secondary: ElunaiColors.forestGreenSoft,
        onSecondary: ElunaiColors.storybookCream,
        tertiary: ElunaiColors.honeyYellow,
        onTertiary: ElunaiColors.storybookInk,
        error: const Color(0xFFB3261E),
        onError: Colors.white,
        surface: ElunaiColors.storybookSurface,
        onSurface: ElunaiColors.storybookInk,
        onSurfaceVariant: ElunaiColors.storybookInkMuted,
        outline: ElunaiColors.forestGreen.withValues(alpha: 0.22),
        outlineVariant: ElunaiColors.storybookInkMuted.withValues(alpha: 0.2),
        shadow: ElunaiColors.storybookInk.withValues(alpha: 0.08),
        scrim: Colors.black.withValues(alpha: 0.35),
        inverseSurface: ElunaiColors.forestGreen,
        onInverseSurface: ElunaiColors.storybookCream,
        inversePrimary: ElunaiColors.honeyYellow,
        surfaceContainerHighest: ElunaiColors.storybookCreamDeep,
      ),
      scaffoldBackgroundColor: ElunaiColors.storybookCream,
      dividerColor: ElunaiColors.storybookInk.withValues(alpha: 0.08),
    );

    final textTheme = ElunaiTextStyles.nunitoTextTheme(base.textTheme).apply(
      bodyColor: ElunaiColors.storybookInk,
      displayColor: ElunaiColors.forestGreen,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: ElunaiColors.storybookInk,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: ElunaiColors.storybookInk,
        ),
      ),
      cardTheme: CardThemeData(
        color: ElunaiColors.storybookSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppSizes.cardRadius),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadowColor: ElunaiColors.storybookInk.withValues(alpha: 0.06),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ElunaiColors.storybookCreamDeep,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: ElunaiColors.forestGreen,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ElunaiSpacing.md,
          vertical: ElunaiSpacing.sm + 2,
        ),
        hintStyle: TextStyle(
          color: ElunaiColors.storybookInkMuted.withValues(alpha: 0.55),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ElunaiSpacing.lg,
            vertical: ElunaiSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: ElunaiColors.forestGreen,
          foregroundColor: ElunaiColors.storybookCream,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ElunaiSpacing.lg,
            vertical: ElunaiSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: ElunaiColors.forestGreen,
          foregroundColor: ElunaiColors.storybookCream,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: ElunaiSpacing.lg,
            vertical: ElunaiSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
            color: ElunaiColors.forestGreen.withValues(alpha: 0.45),
          ),
          foregroundColor: ElunaiColors.forestGreen,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ElunaiColors.storybookSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: ElunaiColors.honeyYellow.withValues(alpha: 0.55),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.15,
            color: selected
                ? ElunaiColors.forestGreen
                : ElunaiColors.storybookInk.withValues(alpha: 0.72),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? ElunaiColors.forestGreen
                : ElunaiColors.storybookInk.withValues(alpha: 0.62),
            size: 24,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ElunaiColors.forestGreen,
        contentTextStyle: const TextStyle(color: ElunaiColors.storybookCream),
      ),
      pageTransitionsTheme: dark.pageTransitionsTheme,
    );
  }
}
