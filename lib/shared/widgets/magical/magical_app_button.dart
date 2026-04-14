import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

enum MagicalButtonVariant { primary, secondary }

/// Bouton arrondi, léger scale + haptic au tap.
class MagicalAppButton extends StatefulWidget {
  const MagicalAppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = MagicalButtonVariant.primary,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final MagicalButtonVariant variant;
  final bool expanded;

  @override
  State<MagicalAppButton> createState() => _MagicalAppButtonState();
}

class _MagicalAppButtonState extends State<MagicalAppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _tapDown() async {
    if (widget.onPressed == null) return;
    await _press.forward();
  }

  Future<void> _tapUp() async {
    await _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.variant == MagicalButtonVariant.primary;
    final gradient = isPrimary ? LunoraColors.ctaGlow : null;
    final fg = isPrimary ? LunoraColors.warmBeige : LunoraColors.warmBeige;
    final border = isPrimary
        ? null
        : Border.all(color: LunoraColors.warmBeige.withValues(alpha: 0.28));

    final child = ScaleTransition(
      scale: _scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: LunoraSpacing.radiusLg,
          color: isPrimary
              ? null
              : LunoraColors.nightBlueLift.withValues(alpha: 0.82),
          gradient: gradient,
          border: border,
          boxShadow: isPrimary && widget.onPressed != null
              ? LunoraColors.primaryGlow(opacity: 0.28)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: LunoraSpacing.radiusLg,
            onTap: widget.onPressed == null
                ? null
                : () async {
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  },
            onHighlightChanged: (v) {
              if (widget.onPressed == null) return;
              if (v) {
                _tapDown();
              } else {
                _tapUp();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LunoraSpacing.lg,
                vertical: LunoraSpacing.md + 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 22, color: fg),
                    const SizedBox(width: LunoraSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.expanded) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}
