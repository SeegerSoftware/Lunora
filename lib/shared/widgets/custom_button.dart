import 'package:flutter/material.dart';

import 'magical/magical_app_button.dart';

/// CTA du design system Lunora : même comportement que [MagicalAppButton]
/// (dégradé, haptique, animation légère), nom explicite pour les écrans « produit ».
class LunoraCustomButton extends StatelessWidget {
  const LunoraCustomButton({
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
  Widget build(BuildContext context) {
    return MagicalAppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      variant: variant,
      expanded: expanded,
    );
  }
}
