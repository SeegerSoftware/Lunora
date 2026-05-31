import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

/// CTA formulaire (connexion, etc.) : même ADN arrondi que le reste de Elunai.
class ElunaiPrimaryButton extends StatelessWidget {
  const ElunaiPrimaryButton({
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
    final cs = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        elevation: light ? 0 : 0.2,
        backgroundColor: light ? cs.primary : ElunaiColors.warmBeige,
        foregroundColor: light ? cs.onPrimary : ElunaiColors.nightBlueDeep,
        disabledBackgroundColor: light
            ? cs.primary.withValues(alpha: 0.35)
            : ElunaiColors.warmBeigeDim.withValues(alpha: 0.75),
        disabledForegroundColor: light
            ? cs.onPrimary.withValues(alpha: 0.55)
            : ElunaiColors.nightBlueDeep.withValues(alpha: 0.55),
        padding: const EdgeInsets.symmetric(
          horizontal: ElunaiSpacing.lg,
          vertical: ElunaiSpacing.md + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: light
                ? ElunaiColors.forestGreen.withValues(alpha: 0.12)
                : ElunaiColors.starGold.withValues(alpha: 0.26),
          ),
        ),
        minimumSize: const Size.fromHeight(54),
      ),
      child: isLoading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: light ? cs.onPrimary : ElunaiColors.nightBlueDeep,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: ElunaiSpacing.sm),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: light ? cs.onPrimary : ElunaiColors.nightBlueDeep,
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
