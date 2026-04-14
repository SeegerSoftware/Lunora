import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../shared/models/child_profile.dart';

final childProfileProvider =
    NotifierProvider<ChildProfileNotifier, ChildProfile?>(
      ChildProfileNotifier.new,
    );

class ChildProfileNotifier extends Notifier<ChildProfile?> {
  @override
  ChildProfile? build() => null;

  Future<void> reloadFromRepositoryFor(String userId) async {
    state = await ref.read(childProfileRepositoryProvider).fetchForUser(userId);
  }

  void hydrate(ChildProfile? profile) {
    state = profile;
  }

  Future<void> upsert(ChildProfile profile) async {
    await ref.read(childProfileRepositoryProvider).upsert(profile);
    state = profile;
  }

  void clear() {
    state = null;
  }
}
