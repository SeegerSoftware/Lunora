import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/child_profile_providers.dart';

class ChildSelector extends ConsumerWidget {
  const ChildSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(childProfilesProvider);
    final active = state.activeProfile;
    if (active == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Changer d’enfant',
      onSelected: (value) {
        if (value == '_add') {
          context.push('/children');
          return;
        }
        ref.read(childProfilesProvider.notifier).select(value);
      },
      itemBuilder: (context) => [
        for (final profile in state.profiles)
          PopupMenuItem(value: profile.id, child: Text(profile.firstName)),
        const PopupMenuDivider(),
        const PopupMenuItem(value: '_add', child: Text('Ajouter un enfant')),
      ],
      child: Chip(
        label: Text(active.firstName),
        avatar: const Icon(Icons.child_care_rounded, size: 18),
        deleteIcon: const Icon(Icons.arrow_drop_down_rounded),
        onDeleted: () {},
      ),
    );
  }
}
