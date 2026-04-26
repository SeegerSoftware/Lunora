import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/models/enums/story_plan.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/subscription_providers.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  static final StoryPlan _plan = StoryPlan.elunai;

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
      appBar: ElunaiAppBar(
        title: 'Abonnement',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: LunoraScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: ListView(
            padding: LunoraSpacing.screen,
            children: [
              LunoraFadeIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Un seul abonnement : histoires du soir personnalisées, paiement sécurisé avec Stripe.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.84),
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
                                  ? 'Aucun abonnement actif'
                                  : 'Abonnement ${subscription.planId}',
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
                      'Offre',
                      style: LunoraTextStyles.sectionTitle(theme.textTheme),
                    ),
                    const SizedBox(height: LunoraSpacing.sm),
                    Material(
                      color: LunoraColors.nightBlueLift.withValues(alpha: 0.55),
                      borderRadius: LunoraSpacing.radiusMd,
                      child: InkWell(
                        borderRadius: LunoraSpacing.radiusMd,
                        onTap: () {
                          context.push(
                            '/stripe-checkout?planId=${Uri.encodeComponent(_plan.planId)}',
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: LunoraSpacing.lg,
                            vertical: LunoraSpacing.md,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: LunoraSpacing.xs,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: LunoraColors.violetGlow.withValues(alpha: 0.28),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _plan.marketingTag,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: LunoraColors.warmBeige,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: LunoraSpacing.xs),
                                    Text(
                                      _plan.displayLabel,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: LunoraColors.warmBeige,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: LunoraSpacing.xxs),
                                    Text(
                                      'Histoires d’environ ${_plan.targetStoryMinutes} minutes, adaptées au profil.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: LunoraColors.mist.withValues(alpha: 0.72),
                                      ),
                                    ),
                                    const SizedBox(height: LunoraSpacing.xs),
                                    Text(
                                      _plan.monthlyPriceLabel,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: LunoraColors.starGoldSoft,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: LunoraSpacing.xs),
                                    ..._plan.keyBenefits.map(
                                      (benefit) => Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(
                                          '• $benefit',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: LunoraColors.mist.withValues(alpha: 0.72),
                                          ),
                                        ),
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
