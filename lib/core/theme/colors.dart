import 'package:flutter/material.dart';

/// Palette « nuit magique » — calme, lisible, chaleureux.
abstract final class LunoraColors {
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

  static const LinearGradient nightSkyVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF12294D), nightBlue, nightBlueDeep],
    stops: [0.0, 0.45, 1.0],
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
