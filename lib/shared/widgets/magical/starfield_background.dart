import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// Couche d’étoiles très légère (CustomPainter + une animation lente).
class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({
    super.key,
    required this.child,
    this.starCount = 48,
  });

  final Widget child;
  final int starCount;

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _StarfieldPainter(
                  t: _controller.value,
                  count: widget.starCount,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({required this.t, required this.count});

  final double t;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < count; i++) {
      final x = (i * 9973 % 1000 / 1000.0) * size.width;
      final y = ((i * 7919) % 1000 / 1000.0) * size.height;
      final phase = (i * 0.37) % (math.pi * 2);
      final twinkle =
          0.25 + 0.75 * (0.5 + 0.5 * math.sin(t * math.pi * 2 + phase));
      final r = i % 5 == 0 ? 1.6 : 1.0;
      final gold = i % 7 == 0;
      final paint = Paint()
        ..color = (gold ? LunoraColors.starGold : LunoraColors.moonIvory)
            .withValues(alpha: twinkle * (gold ? 0.55 : 0.35))
        ..isAntiAlias = true;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
    // Petite lueur diffuse en haut
    final mist = Paint()
      ..shader = RadialGradient(
        colors: [
          LunoraColors.violetSoft.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        radius: 0.55,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.55));
    canvas.drawRect(Offset.zero & size, mist);
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.count != count;
}
