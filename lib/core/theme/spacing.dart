import 'package:flutter/material.dart';

/// Espacements et rayons cohérents (UI magique / parental).
abstract final class LunoraSpacing {
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double xxl = 36;
  static const double xxxl = 48;

  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  static const EdgeInsets reader = EdgeInsets.fromLTRB(md, xl, md, xxl);

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(18));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(32));

  static const double readerMaxWidth = 560;
  static const double storyCardWidth = 196;
  static const double storyCardImageHeight = 112;
}
