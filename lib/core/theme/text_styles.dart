import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Typo douce (Nunito) — hiérarchie simple pour enfants + parents.
abstract final class LunoraTextStyles {
  static TextTheme nunitoTextTheme(TextTheme base) {
    final n = GoogleFonts.nunitoTextTheme(base);
    return n.copyWith(
      displayLarge: n.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineMedium: n.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleLarge: n.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: n.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      titleSmall: n.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: n.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      bodyMedium: n.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodySmall: n.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      labelLarge: n.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }

  static TextStyle greetingNight(TextTheme t) {
    return GoogleFonts.nunito(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.2,
      color: LunoraColors.warmBeige,
      letterSpacing: -0.4,
    );
  }

  static TextStyle greetingSub(TextTheme t) {
    return GoogleFonts.nunito(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.35,
      color: LunoraColors.mist.withValues(alpha: 0.82),
    );
  }

  static TextStyle storyReaderTitle(TextTheme t) {
    return GoogleFonts.nunito(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.25,
      color: LunoraColors.warmBeige,
    );
  }

  static TextStyle storyReaderChapterMeta(TextTheme t) {
    return GoogleFonts.nunito(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: LunoraColors.mist.withValues(alpha: 0.88),
    );
  }

  static TextStyle storyReaderBody(TextTheme t) {
    return GoogleFonts.nunito(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      height: 1.75,
      letterSpacing: 0.12,
      color: LunoraColors.warmBeige.withValues(alpha: 0.96),
    );
  }

  static TextStyle sectionTitle(TextTheme t) {
    return GoogleFonts.nunito(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: LunoraColors.warmBeige.withValues(alpha: 0.95),
    );
  }
}
