import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Constantes visuelles communes à toute l’app Elunai.
abstract final class ElunaiLayout {
  static const int starCount = 32;
  static const double readerBodyMaxWidth = 680;
}

/// AppBar standard (titres, couleurs) pour cohérence entre écrans.
class ElunaiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ElunaiAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.titleColor,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  /// Couleur du titre et des icônes (ex. mode liseuse).
  final Color? titleColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = titleColor ??
        (theme.brightness == Brightness.light
            ? LunoraColors.storybookInk
            : LunoraColors.warmBeige);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      iconTheme: IconThemeData(
        color: fg.withValues(alpha: 0.92),
      ),
      actionsIconTheme: IconThemeData(
        color: fg.withValues(alpha: 0.92),
      ),
      leading: leading,
      actions: actions,
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
