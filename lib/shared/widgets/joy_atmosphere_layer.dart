import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Halos doux animés (légers) pour un fond plus joyeux sans surcharger.
class JoyAtmosphereLayer extends StatelessWidget {
  const JoyAtmosphereLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _glow(
            alignment: Alignment.topRight,
            color: LunoraColors.joyPeach.withValues(alpha: 0.22),
            size: 280,
            offset: const Offset(60, -40),
          ),
          _glow(
            alignment: Alignment.bottomLeft,
            color: LunoraColors.joyMint.withValues(alpha: 0.18),
            size: 320,
            offset: const Offset(-80, 40),
          ),
          _glow(
            alignment: Alignment.center,
            color: LunoraColors.joySun.withValues(alpha: 0.08),
            size: 420,
            offset: Offset.zero,
          ),
        ],
      ),
    );
  }

  Widget _glow({
    required Alignment alignment,
    required Color color,
    required double size,
    required Offset offset,
  }) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
