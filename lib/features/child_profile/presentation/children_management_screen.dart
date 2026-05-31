import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../routing/safe_navigation.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/subscription_plan.dart';
import '../../../shared/widgets/elunai_glass_card.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/elunai_primary_button.dart';
import '../../../shared/widgets/elunai_screen_shell.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../subscription/presentation/providers/subscription_providers.dart';
import '../../subscription/services/subscription_service.dart';
import 'providers/child_profile_providers.dart';

class ChildrenManagementScreen extends ConsumerWidget {
  const ChildrenManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider);
    final subscription = ref.watch(subscriptionProvider);
    final childrenState = ref.watch(childProfilesProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Session requise')));
    }
    final plan = SubscriptionService.effectivePlan(
      user: user,
      subscription: subscription,
    );
    final profiles = childrenState.profiles;

    void addChild() {
      if (!plan.canAddChild(profiles.length)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SubscriptionService.childrenLimitMessage(plan)),
          ),
        );
        return;
      }
      context.push('/setup-child?new=1');
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ElunaiAppBar(
        title: 'Mes enfants',
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
              Text(
                '${plan.displayName} · ${profiles.length}/${plan.maxChildren} profils',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ElunaiColors.warmBeige,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: ElunaiSpacing.md),
              for (final profile in profiles) ...[
                _ChildTile(
                  profile: profile,
                  isActive: profile.id == childrenState.activeProfile?.id,
                  onSelect: () => ref
                      .read(childProfilesProvider.notifier)
                      .select(profile.id),
                  onEdit: () => context.push(
                    '/setup-child?childId=${Uri.encodeComponent(profile.id)}',
                  ),
                  onDelete: profiles.length <= 1
                      ? null
                      : () => _deleteProfile(context, ref, profile),
                ),
                const SizedBox(height: ElunaiSpacing.sm),
              ],
              const SizedBox(height: ElunaiSpacing.md),
              ElunaiPrimaryButton(
                label: 'Ajouter un enfant',
                icon: Icons.add_rounded,
                onPressed: addChild,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProfile(
    BuildContext context,
    WidgetRef ref,
    ChildProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Supprimer ${profile.firstName} ?'),
        content: const Text(
          'Le profil sera supprime. Les histoires existantes restent archivees.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(childProfilesProvider.notifier).delete(profile);
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({
    required this.profile,
    required this.isActive,
    required this.onSelect,
    required this.onEdit,
    this.onDelete,
  });

  final ChildProfile profile;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ElunaiGlassCard(
      child: Row(
        children: [
          Icon(
            Icons.child_care_rounded,
            color: isActive ? ElunaiColors.starGoldSoft : ElunaiColors.mist,
          ),
          const SizedBox(width: ElunaiSpacing.sm),
          Expanded(
            child: InkWell(
              onTap: onSelect,
              child: Text(
                profile.firstName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (isActive) const Text('Actif'),
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: onEdit),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
