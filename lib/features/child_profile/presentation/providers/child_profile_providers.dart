import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/validation/child_profile_rules.dart';
import '../../../../shared/models/child_profile.dart';

class ChildProfilesState {
  const ChildProfilesState({this.profiles = const [], this.activeChildId});

  final List<ChildProfile> profiles;
  final String? activeChildId;

  ChildProfile? get activeProfile {
    if (profiles.isEmpty) return null;
    return profiles
            .where((profile) => profile.id == activeChildId)
            .firstOrNull ??
        profiles.first;
  }

  ChildProfilesState copyWith({
    List<ChildProfile>? profiles,
    String? activeChildId,
    bool clearActiveChild = false,
  }) {
    return ChildProfilesState(
      profiles: profiles ?? this.profiles,
      activeChildId: clearActiveChild
          ? null
          : activeChildId ?? this.activeChildId,
    );
  }
}

final childProfilesProvider =
    NotifierProvider<ChildProfilesNotifier, ChildProfilesState>(
      ChildProfilesNotifier.new,
    );

final childProfileProvider = Provider<ChildProfile?>((ref) {
  return ref.watch(childProfilesProvider).activeProfile;
});

class ChildProfilesNotifier extends Notifier<ChildProfilesState> {
  @override
  ChildProfilesState build() => const ChildProfilesState();

  Future<void> reloadFromRepositoryFor(String userId) async {
    final profiles = await ref
        .read(childProfileRepositoryProvider)
        .fetchAllForUser(userId);
    state = ChildProfilesState(
      profiles: profiles,
      activeChildId: _validActiveId(profiles, state.activeChildId),
    );
  }

  void select(String childId) {
    if (state.profiles.any((profile) => profile.id == childId)) {
      state = state.copyWith(activeChildId: childId);
    }
  }

  void hydrate(ChildProfile? profile) {
    state = profile == null
        ? const ChildProfilesState()
        : ChildProfilesState(profiles: [profile], activeChildId: profile.id);
  }

  Future<void> upsert(ChildProfile profile) async {
    final normalized = ChildProfileRules.normalize(profile);
    final err = ChildProfileRules.validate(normalized);
    if (err != null) throw Exception(err);
    await ref.read(childProfileRepositoryProvider).upsert(normalized);
    final profiles = [
      for (final existing in state.profiles)
        if (existing.id != normalized.id) existing,
      normalized,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = ChildProfilesState(
      profiles: profiles,
      activeChildId: normalized.id,
    );
  }

  Future<void> delete(ChildProfile profile) async {
    if (state.profiles.length <= 1) {
      throw Exception('Conservez au moins un profil enfant.');
    }
    await ref.read(childProfileRepositoryProvider).delete(profile);
    final profiles = state.profiles
        .where((existing) => existing.id != profile.id)
        .toList();
    state = ChildProfilesState(
      profiles: profiles,
      activeChildId: _validActiveId(profiles, state.activeChildId),
    );
  }

  void clear() {
    state = const ChildProfilesState();
  }

  String? _validActiveId(List<ChildProfile> profiles, String? current) {
    if (profiles.any((profile) => profile.id == current)) return current;
    return profiles.firstOrNull?.id;
  }
}
