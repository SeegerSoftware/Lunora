import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../shared/models/story.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../child_profile/presentation/providers/child_profile_providers.dart';

final todayStoryProvider = FutureProvider<Story?>((ref) async {
  final user = ref.watch(authSessionProvider);
  final child = ref.watch(childProfileProvider);
  if (user == null || child == null) return null;
  return ref
      .read(storyRepositoryProvider)
      .ensureTodayStory(user: user, child: child);
});

final storyHistoryProvider = FutureProvider<List<Story>>((ref) async {
  final user = ref.watch(authSessionProvider);
  if (user == null) return const [];
  return ref.read(storyRepositoryProvider).historyForUser(user.id);
});

final storyByIdProvider = FutureProvider.family<Story?, String>((
  ref,
  id,
) async {
  return ref.read(storyRepositoryProvider).findById(id);
});
