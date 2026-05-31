import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/social_auth_config.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../auth_navigation.dart';
import '../providers/auth_providers.dart';

/// Social auth simplifié : Google uniquement (pour l'instant).
class SocialAuthSection extends ConsumerStatefulWidget {
  const SocialAuthSection({super.key});

  @override
  ConsumerState<SocialAuthSection> createState() => _SocialAuthSectionState();
}

class _SocialAuthSectionState extends ConsumerState<SocialAuthSection> {
  String? _busy;

  Future<void> _run(String label, Future<void> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = label);
    try {
      await action();
      if (!mounted) return;
      navigateAfterAuthenticated(context, ref);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SocialAuthConfig.googleSignInConfigured) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: light
                    ? ElunaiColors.storybookInkMuted.withValues(alpha: 0.2)
                    : ElunaiColors.mist.withValues(alpha: 0.25),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ElunaiSpacing.md),
              child: Text(
                'connexion rapide',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: light
                      ? ElunaiColors.storybookInkMuted
                      : ElunaiColors.mist.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: light
                    ? ElunaiColors.storybookInkMuted.withValues(alpha: 0.2)
                    : ElunaiColors.mist.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
        const SizedBox(height: ElunaiSpacing.md),
        _SocialTile(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google',
          busy: _busy == 'google',
          onTap: () => _run(
            'google',
            () => ref.read(authSessionProvider.notifier).signInWithGoogle(),
          ),
        ),
      ],
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return Material(
      color: light
          ? ElunaiColors.storybookSurface
          : ElunaiColors.nightBlueLift.withValues(alpha: 0.65),
      borderRadius: ElunaiSpacing.radiusMd,
      child: InkWell(
        borderRadius: ElunaiSpacing.radiusMd,
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ElunaiSpacing.lg,
            vertical: ElunaiSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: light
                    ? ElunaiColors.forestGreen
                    : ElunaiColors.warmBeige,
                size: 26,
              ),
              const SizedBox(width: ElunaiSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: light
                        ? ElunaiColors.storybookInk
                        : ElunaiColors.warmBeige,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: light
                      ? ElunaiColors.storybookInkMuted.withValues(alpha: 0.55)
                      : ElunaiColors.mist.withValues(alpha: 0.45),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
