import 'package:flutter/material.dart';

import 'text_styles.dart';
import 'theme.dart';

/// Point d’entrée historique : délègue au design system [ElunaiTheme].
abstract final class AppTheme {
  static ThemeData get dark => ElunaiTheme.dark;

  static ThemeData get light => ElunaiTheme.light;

  static TextStyle storyReaderTitle(TextTheme textTheme) =>
      ElunaiTextStyles.storyReaderTitle(textTheme);

  static TextStyle storyReaderChapterMeta(TextTheme textTheme) =>
      ElunaiTextStyles.storyReaderChapterMeta(textTheme);

  static TextStyle storyReaderBody(TextTheme textTheme) =>
      ElunaiTextStyles.storyReaderBody(textTheme);

  static TextStyle storyReaderMetaOnCard(TextTheme textTheme) =>
      ElunaiTextStyles.storyReaderMetaOnCard(textTheme);
}
