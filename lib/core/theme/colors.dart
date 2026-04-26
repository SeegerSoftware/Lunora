import 'package:flutter/material.dart';

/// Palette « nuit magique » + variant **livre pour enfants** (maquettes crème / vert).
abstract final class LunoraColors {
  // —— Storybook (jour doux) ——
  static const Color storybookCream = Color(0xFFFDF9F3);
  static const Color storybookCreamDeep = Color(0xFFF3EBE0);
  static const Color storybookInk = Color(0xFF1E2D26);
  static const Color storybookInkMuted = Color(0xFF4A5C54);
  static const Color forestGreen = Color(0xFF2D4A3E);
  static const Color forestGreenSoft = Color(0xFF3D5F4F);
  static const Color heroCardBlue = Color(0xFF1B2F4A);
  static const Color heroCardBlueDeep = Color(0xFF142436);
  static const Color honeyYellow = Color(0xFFF3D56A);
  static const Color honeyYellowDeep = Color(0xFFE8C547);

  /// Fond crème très léger pour sections contrastées.
  static const Color storybookSurface = Color(0xFFFFFFFF);
  static const Color nightBlue = Color(0xFF0B1E3B);
  static const Color nightBlueDeep = Color(0xFF050F22);
  static const Color nightBlueLift = Color(0xFF152A45);

  static const Color violetSoft = Color(0xFF6C63FF);
  static const Color violetGlow = Color(0xFF8B84FF);
  static const Color violetMuted = Color(0xFF4A4580);

  static const Color warmBeige = Color(0xFFF5E6CA);
  static const Color warmBeigeDim = Color(0xFFD9C4A8);

  static const Color starGold = Color(0xFFE8C547);
  static const Color starGoldSoft = Color(0xFFFFF2C4);

  static const Color moonIvory = Color(0xFFFFF8ED);
  static const Color mist = Color(0xFFE8E4F8);

  /// Fonds lecture coucher : jamais noir pur, chaleur légère.
  static const Color readerInk = Color(0xFF121A28);
  static const Color readerInkDeep = Color(0xFF0C1018);
  static const Color readerCard = Color(0xFF1C2636);
  static const Color readerCardBorder = Color(0xFF2A3548);
  static const Color readerTextPrimary = Color(0xFFF3E8D4);
  static const Color readerTextSecondary = Color(0xFFC9B8A8);

  static const LinearGradient readerCanvasVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A2436),
      readerInk,
      readerInkDeep,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient nightSkyVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF12294D), nightBlue, nightBlueDeep],
    stops: [0.0, 0.45, 1.0],
  );

  /// Fond « ciel magique » plus chaleureux (accueil, navigation).
  static const LinearGradient joySkyVertical = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3A6E),
      Color(0xFF2D1B69),
      Color(0xFF0F2854),
      nightBlueDeep,
    ],
    stops: [0.0, 0.35, 0.72, 1.0],
  );

  static const Color joyPeach = Color(0xFFFFB4A8);
  static const Color joyMint = Color(0xFF7EE0C3);
  static const Color joySun = Color(0xFFFFE08A);

  /// Mode liseuse (papier / encre chaude).
  static const Color ereaderPaper = Color(0xFFF7F0E4);
  static const Color ereaderPaperDeep = Color(0xFFE8DCC8);
  static const Color ereaderInk = Color(0xFF2C2418);
  static const Color ereaderInkMuted = Color(0xFF5C5246);

  static const LinearGradient ereaderPaperVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFBF5), ereaderPaper, ereaderPaperDeep],
    stops: [0.0, 0.42, 1.0],
  );

  static const LinearGradient cardAura = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3358), nightBlueLift],
  );

  static const LinearGradient ctaGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violetGlow, violetSoft],
  );

  /// Halo discret derrière un CTA (box-shadow simulé par overlay).
  static List<BoxShadow> primaryGlow({double opacity = 0.35}) => [
    BoxShadow(
      color: violetSoft.withValues(alpha: opacity),
      blurRadius: 22,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: starGold.withValues(alpha: 0.12),
      blurRadius: 40,
      spreadRadius: -4,
      offset: const Offset(0, 12),
    ),
  ];
}
