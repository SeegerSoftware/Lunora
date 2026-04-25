import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

/// CTA formulaire (connexion, etc.) : même ADN arrondi que le reste de Lunora.
class LunoraPrimaryButton extends StatelessWidget {
  const LunoraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          elevation: 0.2,
          backgroundColor: LunoraColors.warmBeige,
          foregroundColor: LunoraColors.nightBlueDeep,
          disabledBackgroundColor: LunoraColors.warmBeigeDim.withValues(alpha: 0.75),
          disabledForegroundColor: LunoraColors.nightBlueDeep.withValues(alpha: 0.55),
          padding: const EdgeInsets.symmetric(
            horizontal: LunoraSpacing.lg,
            vertical: LunoraSpacing.md + 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: LunoraColors.starGold.withValues(alpha: 0.26),
            ),
          ),
          minimumSize: const Size.fromHeight(54),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: LunoraColors.nightBlueDeep,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: LunoraSpacing.sm),
                  ],
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: LunoraColors.nightBlueDeep,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                  ),
                ],
              ),
      );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
