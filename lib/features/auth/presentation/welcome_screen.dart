import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_page_header.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';
import '../../legal/presentation/terms_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: LunoraScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: Padding(
            padding: AppSizes.screenPadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    LunoraFadeIn(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LunoraPageHeader(
                            badge: 'Histoires personnalisées pour le soir',
                            icon: Icons.auto_stories_rounded,
                            title: 'Elunai',
                            subtitle:
                                'Une bibliothèque magique qui s’adapte à l’âge, aux goûts et au rythme de ton enfant.',
                          ),
                          const SizedBox(height: LunoraSpacing.xl),
                          Row(
                            children: const [
                              Expanded(
                                child: _TrustPoint(
                                  icon: Icons.shield_outlined,
                                  label: 'Sécurisé',
                                ),
                              ),
                              SizedBox(width: LunoraSpacing.sm),
                              Expanded(
                                child: _TrustPoint(
                                  icon: Icons.bedtime_outlined,
                                  label: 'Rituel calme',
                                ),
                              ),
                              SizedBox(width: LunoraSpacing.sm),
                              Expanded(
                                child: _TrustPoint(
                                  icon: Icons.favorite_border_rounded,
                                  label: 'Sur mesure',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    LunoraFadeIn(
                      delay: const Duration(milliseconds: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LunoraPrimaryButton(
                            label: 'Créer un compte',
                            icon: Icons.mail_outline_rounded,
                            onPressed: () => context.push('/signup'),
                          ),
                          const SizedBox(height: LunoraSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/signin'),
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('J’ai déjà un compte'),
                          ),
                          const SizedBox(height: LunoraSpacing.xs),
                          TextButton(
                            onPressed: () =>
                                context.push(TermsScreen.routePath),
                            child: const Text(
                              'Conditions générales d’utilisation',
                            ),
                          ),
                          const SizedBox(height: LunoraSpacing.sm),
                          Text(
                            'Pensé pour les parents, doux pour les enfants.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: LunoraColors.storybookInkMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LunoraColors.storybookSurface.withValues(alpha: 0.86),
        borderRadius: LunoraSpacing.radiusMd,
        border: Border.all(
          color: LunoraColors.forestGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LunoraSpacing.xs,
          vertical: LunoraSpacing.sm,
        ),
        child: Column(
          children: [
            Icon(icon, color: LunoraColors.forestGreen, size: 20),
            const SizedBox(height: LunoraSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: LunoraColors.storybookInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
