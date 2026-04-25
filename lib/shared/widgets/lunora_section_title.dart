import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

class LunoraSectionTitle extends StatelessWidget {
  const LunoraSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: LunoraColors.warmBeige,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
    );
  }
}
