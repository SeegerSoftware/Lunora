import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/enums/story_plan.dart';
import '../../../shared/models/enums/subscription_status.dart';
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
      appBar: AppBar(title: const Text('Abonnement')),
      body: SafeArea(
        child: ListView(
          padding: AppSizes.screenPadding,
          children: [
            Text(
              'Choisissez une durée moyenne d’histoire. Le paiement réel arrive dans une prochaine version.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text('État actuel', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSizes.sm),
            Card(
              child: ListTile(
                title: Text(
                  subscription == null
                      ? 'Aucun abonnement mocké'
                      : 'Plan ${subscription.planId}',
                ),
                subtitle: Text(
                  'Compte : ${user.subscriptionStatus.name} · ${user.selectedPlan ?? 'aucun plan'}',
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text('Plans', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSizes.sm),
            ...StoryPlan.values.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Card(
                  child: ListTile(
                    title: Text(plan.displayLabel),
                    subtitle: Text(
                      'Histoires autour de ${plan.targetStoryMinutes} minutes',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      await ref
                          .read(subscriptionProvider.notifier)
                          .selectMockPlanFor(user: user, plan: plan);
                      ref
                          .read(authSessionProvider.notifier)
                          .applyPlanSelection(
                            planId: plan.planId,
                            status: SubscriptionStatus.active,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Plan sélectionné : ${plan.displayLabel}',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
