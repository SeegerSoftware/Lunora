import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/story_providers.dart';

class StoryHistoryScreen extends ConsumerWidget {
  const StoryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider);
    final historyAsync = ref.watch(storyHistoryProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/welcome');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: SafeArea(
        child: historyAsync.when(
          skipLoadingOnReload: true,
          data: (stories) {
            if (stories.isEmpty) {
              return Padding(
                padding: AppSizes.screenPadding,
                child: Center(
                  child: Text(
                    'Pas encore d’histoires enregistrées. Revenez après une première lecture.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: AppSizes.screenPadding,
              itemCount: stories.length,
              separatorBuilder: (context, _) =>
                  const SizedBox(height: AppSizes.sm),
              itemBuilder: (context, index) {
                final story = stories[index];
                final label = story.dateKey;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.xs,
                    ),
                    title: Text(story.title, style: theme.textTheme.titleSmall),
                    subtitle: Text(
                      '$label · ${story.estimatedReadingMinutes} min',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/story?id=${story.id}'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Padding(
            padding: AppSizes.screenPadding,
            child: Center(
              child: Text('Erreur : $err', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
