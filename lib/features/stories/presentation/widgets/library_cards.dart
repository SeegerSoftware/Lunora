import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

class SeriesProgressIndicator extends StatelessWidget {
  const SeriesProgressIndicator({
    super.key,
    required this.currentChapter,
    required this.totalChapters,
  });

  final int currentChapter;
  final int totalChapters;

  @override
  Widget build(BuildContext context) {
    final total = totalChapters <= 0 ? 1 : totalChapters;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: (currentChapter / total).clamp(0.0, 1.0),
        minHeight: 7,
        backgroundColor: ElunaiColors.storybookCreamDeep,
        color: ElunaiColors.forestGreen,
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ElunaiColors.storybookSurface,
        borderRadius: ElunaiSpacing.radiusLg,
        border: Border.all(
          color: ElunaiColors.forestGreen.withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );
  }
}

class SeriesCard extends BookCard {
  const SeriesCard({super.key, required super.child});
}
