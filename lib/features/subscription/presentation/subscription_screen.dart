import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../routing/safe_navigation.dart';
import '../../../shared/models/enums/subscription_status.dart';
import '../../../shared/models/enums/story_plan.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_glass_card.dart';
import '../../../shared/widgets/lunora_page_header.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
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
    final effectiveStatus = subscription?.status ?? user?.subscriptionStatus;
    final isActive =
        effectiveStatus == SubscriptionStatus.active ||
        effectiveStatus == SubscriptionStatus.grace;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Session requise')));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ElunaiAppBar(
        title: 'Abonnement',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePopOrGo('/home'),
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
                    const LunoraPageHeader(
                      compact: true,
                      icon: Icons.workspace_premium_rounded,
                      title: 'Histoires sans friction',
                      subtitle:
                          'Le paiement est géré par Stripe. Le statut est synchronisé automatiquement côté backend.',
                      badge: 'Stripe Checkout sécurisé',
                    ),
                    const SizedBox(height: LunoraSpacing.xl),
                    _StatusCard(
                      isActive: isActive,
                      statusLabel: effectiveStatus?.name ?? 'none',
                      planId: subscription?.planId,
                      endsAt: subscription?.endsAt,
                    ),
                    const SizedBox(height: LunoraSpacing.lg),
                    _PlanCard(
                      plan: _plan,
                      isActive: isActive,
                      onTap: () => context.push(
                        '/stripe-checkout?planId=${Uri.encodeComponent(_plan.planId)}',
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.lg),
                    LunoraPrimaryButton(
                      label: isActive
                          ? 'Gérer mon abonnement'
                          : 'S’abonner avec Stripe',
                      icon: isActive
                          ? Icons.manage_accounts_rounded
                          : Icons.lock_rounded,
                      onPressed: () => context.push(
                        '/stripe-checkout?planId=${Uri.encodeComponent(_plan.planId)}',
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.sm),
                    Text(
                      'Aucune clé Stripe secrète n’est stockée dans l’app mobile.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: LunoraColors.storybookInkMuted,
                        fontWeight: FontWeight.w600,
                      ),
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isActive,
    required this.statusLabel,
    this.planId,
    this.endsAt,
  });

  final bool isActive;
  final String statusLabel;
  final String? planId;
  final DateTime? endsAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LunoraGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isActive ? Icons.verified_rounded : Icons.lock_open_rounded,
            color: isActive
                ? LunoraColors.forestGreen
                : LunoraColors.honeyYellowDeep,
            size: 30,
          ),
          const SizedBox(width: LunoraSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Abonnement actif' : 'Aucun abonnement actif',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: LunoraColors.storybookInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: LunoraSpacing.xxs),
                Text(
                  planId == null
                      ? 'Statut compte : $statusLabel'
                      : 'Plan : $planId · statut $statusLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: LunoraColors.storybookInkMuted,
                    height: 1.35,
                  ),
                ),
                if (endsAt != null) ...[
                  const SizedBox(height: LunoraSpacing.xs),
                  Text(
                    'Fin de période : ${endsAt!.day.toString().padLeft(2, '0')}.${endsAt!.month.toString().padLeft(2, '0')}.${endsAt!.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: LunoraColors.storybookInkMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isActive,
    required this.onTap,
  });

  final StoryPlan plan;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: LunoraColors.storybookSurface,
      borderRadius: LunoraSpacing.radiusLg,
      child: InkWell(
        borderRadius: LunoraSpacing.radiusLg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(LunoraSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: LunoraSpacing.radiusLg,
            border: Border.all(
              color: isActive
                  ? LunoraColors.forestGreen.withValues(alpha: 0.28)
                  : LunoraColors.honeyYellowDeep.withValues(alpha: 0.32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.displayLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: LunoraColors.storybookInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    plan.monthlyPriceLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: LunoraColors.forestGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LunoraSpacing.xs),
              Text(
                'Histoires d’environ ${plan.targetStoryMinutes} minutes, adaptées au profil enfant.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: LunoraColors.storybookInkMuted,
                  height: 1.38,
                ),
              ),
              const SizedBox(height: LunoraSpacing.md),
              ...plan.keyBenefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: LunoraSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: LunoraColors.forestGreen,
                      ),
                      const SizedBox(width: LunoraSpacing.xs),
                      Expanded(
                        child: Text(
                          benefit,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LunoraColors.storybookInk,
                            height: 1.32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
