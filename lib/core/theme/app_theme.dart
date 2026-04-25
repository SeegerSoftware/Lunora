import 'package:flutter/material.dart';

import 'text_styles.dart';
import 'theme.dart';

/// Point d’entrée historique : délègue au design system [LunoraTheme].
abstract final class AppTheme {
  static ThemeData get dark => LunoraTheme.dark;

  static ThemeData get light => LunoraTheme.light;

  static TextStyle storyReaderTitle(TextTheme textTheme) =>
      LunoraTextStyles.storyReaderTitle(textTheme);

  static TextStyle storyReaderChapterMeta(TextTheme textTheme) =>
      LunoraTextStyles.storyReaderChapterMeta(textTheme);

  static TextStyle storyReaderBody(TextTheme textTheme) =>
      LunoraTextStyles.storyReaderBody(textTheme);

  static TextStyle storyReaderMetaOnCard(TextTheme textTheme) =>
      LunoraTextStyles.storyReaderMetaOnCard(textTheme);
}
