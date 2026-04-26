import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

class LunoraSectionTitle extends StatelessWidget {
  const LunoraSectionTitle(this.text, {super.key, this.foregroundColor});

  final String text;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: foregroundColor ??
                (Theme.of(context).brightness == Brightness.light
                    ? LunoraColors.forestGreen
                    : LunoraColors.warmBeige),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
    );
  }
}
