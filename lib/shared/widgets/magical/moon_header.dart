import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// En-tête doux : lune + titre.
class MoonHeader extends StatelessWidget {
  const MoonHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MoonDisc(),
        const SizedBox(width: LunoraSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: LunoraColors.warmBeige,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: LunoraSpacing.xxs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LunoraColors.mist.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _MoonDisc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            LunoraColors.moonIvory,
            LunoraColors.warmBeigeDim.withValues(alpha: 0.85),
          ],
          center: const Alignment(-0.35, -0.35),
          radius: 0.95,
        ),
        boxShadow: [
          BoxShadow(
            color: LunoraColors.starGold.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.nightlight_round,
          color: LunoraColors.nightBlue.withValues(alpha: 0.55),
          size: 26,
        ),
      ),
    );
  }
}
