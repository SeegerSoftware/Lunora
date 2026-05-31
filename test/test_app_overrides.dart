import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elunai_v00/core/di/providers.dart';
import 'package:elunai_v00/features/auth/data/auth_repository.dart';
import 'package:elunai_v00/features/auth/presentation/providers/auth_providers.dart';
import 'package:elunai_v00/features/child_profile/data/child_profile_repository.dart';
import 'package:elunai_v00/features/stories/data/story_repository.dart';
import 'package:elunai_v00/features/subscription/data/subscription_repository.dart';
import 'package:elunai_v00/shared/models/child_profile.dart';
import 'package:elunai_v00/shared/models/enums/story_format.dart';
import 'package:elunai_v00/shared/models/enums/story_tone.dart';
import 'package:elunai_v00/shared/models/enums/subscription_status.dart';
import 'package:elunai_v00/shared/models/story.dart';
import 'package:elunai_v00/shared/models/subscription.dart';
import 'package:elunai_v00/shared/models/user_model.dart';

List<Override> testAppOverrides() {
  final auth = _FakeAuthRepository();
  final childProfiles = _FakeChildProfileRepository();
  final stories = _FakeStoryRepository();
  return [
    firebaseAuthSyncProvider.overrideWith((ref) {}),
    authRepositoryProvider.overrideWithValue(auth),
    childProfileRepositoryProvider.overrideWithValue(childProfiles),
    storyRepositoryProvider.overrideWithValue(stories),
    subscriptionRepositoryProvider.overrideWithValue(
      _FakeSubscriptionRepository(),
    ),
  ];
}

class _FakeAuthRepository implements AuthRepository {
  UserModel? _current;

  @override
  Future<UserModel?> restoreSession() async => _current;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    return _setCurrent(email);
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
  }) async {
    return _setCurrent(email);
  }

  @override
  Future<UserModel> signInWithApple() async => _setCurrent('apple@elunai.test');

  @override
  Future<UserModel> signInWithFacebook() async {
    return _setCurrent('facebook@elunai.test');
  }

  @override
  Future<UserModel> signInWithGoogle() async =>
      _setCurrent('google@elunai.test');

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> deleteAccount() async {
    _current = null;
  }

  @override
  Future<void> signOut() async {
    _current = null;
  }

  UserModel _setCurrent(String email) {
    final user = UserModel(
      id: 'test-user',
      email: email,
      createdAt: DateTime(2026),
      subscriptionStatus: SubscriptionStatus.none,
    );
    _current = user;
    return user;
  }
}

class _FakeChildProfileRepository implements ChildProfileRepository {
  ChildProfile? _profile;

  @override
  Future<ChildProfile?> fetchForUser(String userId) async => _profile;

  @override
  Future<void> upsert(ChildProfile profile) async {
    _profile = profile;
  }

  @override
  Future<void> clear() async {
    _profile = null;
  }
}

class _FakeStoryRepository implements StoryRepository {
  Story? _story;

  @override
  Future<Story?> findTodayStory({
    required UserModel user,
    required ChildProfile child,
  }) async => _story;

  @override
  Future<void> preserveActiveSeriesProfile({
    required UserModel user,
    required ChildProfile child,
  }) async {}

  @override
  Future<void> restartActiveSeries({
    required UserModel user,
    required ChildProfile child,
  }) async {
    _story = null;
  }

  @override
  Future<Story> ensureTodayStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    return _story ??= _storyFor(user, child);
  }

  @override
  Future<Story> adminRegenerateTodayStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    _story = _storyFor(user, child);
    return _story!;
  }

  @override
  Future<Story> adminGenerateUniqueStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    _story = _storyFor(user, child);
    return _story!;
  }

  @override
  Future<List<Story>> adminGenerateSevenChapterStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    _story = _storyFor(user, child);
    return [_story!];
  }

  @override
  Future<List<Story>> historyForUser(String userId) async {
    return _story == null ? const [] : [_story!];
  }

  @override
  Future<Story?> findById(String storyId) async => _story;

  @override
  Future<void> setStoryUserFeedback({
    required String storyId,
    required int feedback,
  }) async {}

  @override
  Future<void> reset() async {
    _story = null;
  }

  Story _storyFor(UserModel user, ChildProfile child) {
    return Story(
      id: 'story-test',
      childId: child.id,
      userId: user.id,
      dateKey: '2026-05-18',
      title: 'Ce soir pour ${child.firstName}',
      content: '${child.firstName} regarde les etoiles et trouve le sommeil.',
      summary: 'Une histoire calme pour ${child.firstName}.',
      theme: child.preferredThemes.isEmpty
          ? 'etoiles'
          : child.preferredThemes.first,
      tone: StoryTone.reassuring,
      estimatedReadingMinutes: 10,
      format: StoryFormat.serializedChapters,
      chapterNumber: 1,
      totalChapters: 7,
      generationSource: 'test',
      createdAt: DateTime(2026, 5, 18),
    );
  }
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<Subscription?> current(String userId) async => null;

  @override
  Future<void> clear() async {}
}
