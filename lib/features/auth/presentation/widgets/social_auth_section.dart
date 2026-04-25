import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../auth_navigation.dart';
import '../providers/auth_providers.dart';

/// Boutons Google / Apple / Facebook (selon plateforme).
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: LunoraColors.mist.withValues(alpha: 0.25))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LunoraSpacing.md),
              child: Text(
                'ou avec',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: LunoraColors.mist.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: LunoraColors.mist.withValues(alpha: 0.25))),
          ],
        ),
        const SizedBox(height: LunoraSpacing.md),
        _SocialTile(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google',
          busy: _busy == 'google',
          onTap: () => _run(
            'google',
            () => ref.read(authSessionProvider.notifier).signInWithGoogle(),
          ),
        ),
        const SizedBox(height: LunoraSpacing.sm),
        _SocialTile(
          icon: Icons.apple_rounded,
          label: 'Apple',
          busy: _busy == 'apple',
          onTap: () => _run(
            'apple',
            () => ref.read(authSessionProvider.notifier).signInWithApple(),
          ),
        ),
        const SizedBox(height: LunoraSpacing.sm),
        _SocialTile(
          icon: Icons.facebook,
          label: 'Facebook',
          busy: _busy == 'facebook',
          onTap: () => _run(
            'facebook',
            () => ref.read(authSessionProvider.notifier).signInWithFacebook(),
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
    return Material(
      color: LunoraColors.nightBlueLift.withValues(alpha: 0.65),
      borderRadius: LunoraSpacing.radiusMd,
      child: InkWell(
        borderRadius: LunoraSpacing.radiusMd,
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LunoraSpacing.lg,
            vertical: LunoraSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, color: LunoraColors.warmBeige, size: 26),
              const SizedBox(width: LunoraSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: LunoraColors.warmBeige,
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
                  color: LunoraColors.mist.withValues(alpha: 0.45),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
