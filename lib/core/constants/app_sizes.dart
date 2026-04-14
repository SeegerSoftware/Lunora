import 'package:flutter/material.dart';

abstract final class AppSizes {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double xxl = 36;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  /// Lecture confortable (histoire du soir).
  static const EdgeInsets readerPadding = EdgeInsets.fromLTRB(md, xl, md, xxl);

  static const double readerMaxWidth = 640;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(18));
}
