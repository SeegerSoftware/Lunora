import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

class ElunaiSectionTitle extends StatelessWidget {
  const ElunaiSectionTitle(this.text, {super.key, this.foregroundColor});

  final String text;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color:
            foregroundColor ??
            (Theme.of(context).brightness == Brightness.light
                ? ElunaiColors.forestGreen
                : ElunaiColors.warmBeige),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
      ),
    );
  }
}
