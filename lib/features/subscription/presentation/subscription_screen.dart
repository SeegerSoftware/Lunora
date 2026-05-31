import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../routing/safe_navigation.dart';
import '../../../shared/models/enums/subscription_status.dart';
import '../../../shared/models/enums/subscription_plan.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/elunai_fade_in.dart';
import '../../../shared/widgets/elunai_glass_card.dart';
import '../../../shared/widgets/elunai_page_header.dart';
import '../../../shared/widgets/elunai_primary_button.dart';
import '../../../shared/widgets/elunai_screen_shell.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/subscription_providers.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  static const _plans = SubscriptionPlan.values;
  static const _defaultPlan = SubscriptionPlan.solo;

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
      body: ElunaiScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: ListView(
            padding: ElunaiSpacing.screen,
            children: [
              ElunaiFadeIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ElunaiPageHeader(
                      compact: true,
                      icon: Icons.workspace_premium_rounded,
                      title: 'Histoires sans friction',
                      subtitle:
                          'Le paiement est géré par Stripe. Le statut est synchronisé automatiquement côté backend.',
                      badge: 'Stripe Checkout sécurisé',
                    ),
                    const SizedBox(height: ElunaiSpacing.xl),
                    _StatusCard(
                      isActive: isActive,
                      statusLabel: effectiveStatus?.name ?? 'none',
                      planId: subscription?.planId,
                      endsAt: subscription?.endsAt,
                    ),
                    const SizedBox(height: ElunaiSpacing.lg),
                    for (final plan in _plans) ...[
                      _PlanCard(
                        plan: plan,
                        isActive:
                            isActive && subscription?.planId == plan.planId,
                        onTap: () => context.push(
                          '/stripe-checkout?planId=${Uri.encodeComponent(plan.planId)}',
                        ),
                      ),
                      const SizedBox(height: ElunaiSpacing.sm),
                    ],
                    const SizedBox(height: ElunaiSpacing.lg),
                    ElunaiPrimaryButton(
                      label: isActive
                          ? 'Gérer mon abonnement'
                          : 'S’abonner avec Stripe',
                      icon: isActive
                          ? Icons.manage_accounts_rounded
                          : Icons.lock_rounded,
                      onPressed: () => context.push(
                        '/stripe-checkout?planId=${Uri.encodeComponent(_defaultPlan.planId)}',
                      ),
                    ),
                    const SizedBox(height: ElunaiSpacing.sm),
                    Text(
                      'Aucune clé Stripe secrète n’est stockée dans l’app mobile.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ElunaiColors.storybookInkMuted,
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
    return ElunaiGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isActive ? Icons.verified_rounded : Icons.lock_open_rounded,
            color: isActive
                ? ElunaiColors.forestGreen
                : ElunaiColors.honeyYellowDeep,
            size: 30,
          ),
          const SizedBox(width: ElunaiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Abonnement actif' : 'Aucun abonnement actif',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ElunaiColors.storybookInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: ElunaiSpacing.xxs),
                Text(
                  planId == null
                      ? 'Statut compte : $statusLabel'
                      : 'Plan : $planId · statut $statusLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ElunaiColors.storybookInkMuted,
                    height: 1.35,
                  ),
                ),
                if (endsAt != null) ...[
                  const SizedBox(height: ElunaiSpacing.xs),
                  Text(
                    'Fin de période : ${endsAt!.day.toString().padLeft(2, '0')}.${endsAt!.month.toString().padLeft(2, '0')}.${endsAt!.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ElunaiColors.storybookInkMuted,
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

  final SubscriptionPlan plan;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: ElunaiColors.storybookSurface,
      borderRadius: ElunaiSpacing.radiusLg,
      child: InkWell(
        borderRadius: ElunaiSpacing.radiusLg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(ElunaiSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: ElunaiSpacing.radiusLg,
            border: Border.all(
              color: isActive
                  ? ElunaiColors.forestGreen.withValues(alpha: 0.28)
                  : ElunaiColors.honeyYellowDeep.withValues(alpha: 0.32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: ElunaiColors.storybookInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    plan.priceLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ElunaiColors.forestGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ElunaiSpacing.xs),
              Text(
                '${plan.dailyStoriesPerChild} histoire par jour par enfant, en lecture texte.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ElunaiColors.storybookInkMuted,
                  height: 1.38,
                ),
              ),
              const SizedBox(height: ElunaiSpacing.md),
              ...plan.keyBenefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: ElunaiSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: ElunaiColors.forestGreen,
                      ),
                      const SizedBox(width: ElunaiSpacing.xs),
                      Expanded(
                        child: Text(
                          benefit,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ElunaiColors.storybookInk,
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
