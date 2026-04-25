import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Pastille enfant douce (initiale + halo), pour personnaliser l’accueil.
class ChildAvatarWidget extends StatelessWidget {
  const ChildAvatarWidget({
    super.key,
    required this.firstName,
    this.size = 52,
  });

  final String firstName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = firstName.trim();
    final letter = t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LunoraColors.ctaGlow,
        boxShadow: LunoraColors.primaryGlow(opacity: 0.25),
        border: Border.all(
          color: LunoraColors.moonIvory.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: LunoraColors.nightBlue,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.38,
            ),
      ),
    );
  }
}
