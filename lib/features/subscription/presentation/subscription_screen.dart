import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/models/enums/story_plan.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/subscription_providers.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider);
    final subscription = ref.watch(subscriptionProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Session requise')));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Abonnement',
          style: theme.textTheme.titleLarge?.copyWith(
            color: LunoraColors.warmBeige,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: LunoraColors.warmBeige.withValues(alpha: 0.9),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: LunoraScreenShell(
        showStarfield: true,
        starCount: 24,
        child: SafeArea(
          child: ListView(
            padding: LunoraSpacing.screen,
            children: [
              LunoraFadeIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choisis une durée moyenne d’histoire, puis passe par l’écran '
                      'de paiement Stripe (ou le mode test sans carte).',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.xl),
                    Text(
                      'État actuel',
                      style: LunoraTextStyles.sectionTitle(theme.textTheme),
                    ),
                    const SizedBox(height: LunoraSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: LunoraSpacing.radiusLg,
                        color: LunoraColors.nightBlueLift.withValues(alpha: 0.75),
                        border: Border.all(
                          color: LunoraColors.mist.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(LunoraSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscription == null
                                  ? 'Aucun abonnement mocké'
                                  : 'Plan ${subscription.planId}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: LunoraColors.warmBeige,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: LunoraSpacing.xs),
                            Text(
                              'Compte : ${user.subscriptionStatus.name} · ${user.selectedPlan ?? 'aucun plan'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: LunoraColors.mist.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.xl),
                    Text(
                      'Plans',
                      style: LunoraTextStyles.sectionTitle(theme.textTheme),
                    ),
                    const SizedBox(height: LunoraSpacing.sm),
                    ...StoryPlan.values.map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: LunoraSpacing.sm),
                        child: Material(
                          color: LunoraColors.nightBlueLift.withValues(alpha: 0.55),
                          borderRadius: LunoraSpacing.radiusMd,
                          child: InkWell(
                            borderRadius: LunoraSpacing.radiusMd,
                            onTap: () {
                              context.push(
                                '/stripe-checkout?planId=${Uri.encodeComponent(plan.planId)}',
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: LunoraSpacing.lg,
                                vertical: LunoraSpacing.md,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.displayLabel,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            color: LunoraColors.warmBeige,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: LunoraSpacing.xxs),
                                        Text(
                                          'Histoires autour de ${plan.targetStoryMinutes} minutes',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: LunoraColors.mist
                                                .withValues(alpha: 0.72),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: LunoraColors.mist.withValues(alpha: 0.45),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.lg),
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
