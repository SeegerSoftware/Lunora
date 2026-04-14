import '../../features/story_memory/domain/story_memory_snapshot.dart';
import '../../features/story_memory/domain/story_world.dart';
import '../../features/story_memory/services/story_world_seed.dart';
import '../../shared/models/child_profile.dart';
import '../../shared/models/story.dart';
import '../../shared/models/subscription.dart';
import '../../shared/models/user_model.dart';
import '../story_generation/series_narrative_seed.dart';

/// Source unique de vérité pour les données mock (session, profil, histoires).
class LunoraMockStore {
  UserModel? sessionUser;
  ChildProfile? childProfile;
  Subscription? subscription;

  final Map<String, Story> _storyByChildAndDateKey = <String, Story>{};
  final Map<String, String> _seriesAnchorDateKeyByChildId = <String, String>{};
  final Map<String, SeriesNarrativeBundle> _seriesNarrativeBySeriesId =
      <String, SeriesNarrativeBundle>{};
  final Map<String, StoryWorld> _storyWorldByChildId = <String, StoryWorld>{};
  final List<StoryMemorySnapshot> _memorySnapshots = <StoryMemorySnapshot>[];

  static String storyCacheKey(String childId, String dateKey) =>
      '$childId|$dateKey';

  Story? storyFor(String childId, String dateKey) =>
      _storyByChildAndDateKey[storyCacheKey(childId, dateKey)];

  void putStory(Story story) {
    _storyByChildAndDateKey[storyCacheKey(story.childId, story.dateKey)] =
        story;
  }

  void removeStoryForDate(String childId, String dateKey) {
    _storyByChildAndDateKey.remove(storyCacheKey(childId, dateKey));
  }

  List<Story> storiesForUser(String userId) {
    return _storyByChildAndDateKey.values
        .where((s) => s.userId == userId)
        .toList();
  }

  Story? storyById(String storyId) {
    for (final s in _storyByChildAndDateKey.values) {
      if (s.id == storyId) return s;
    }
    return null;
  }

  String? seriesAnchorDateKey(String childId) =>
      _seriesAnchorDateKeyByChildId[childId];

  String getOrCreateSeriesAnchorDateKey(String childId, String todayDateKey) {
    return _seriesAnchorDateKeyByChildId.putIfAbsent(
      childId,
      () => todayDateKey,
    );
  }

  void clearSeriesAnchor(String childId) {
    _seriesAnchorDateKeyByChildId.remove(childId);
  }

  /// Même logique que Firestore : stable par [seriesId] tant que le mock vit.
  SeriesNarrativeBundle getOrCreateSeriesNarrative(
    String seriesId,
    String firstName,
  ) {
    return _seriesNarrativeBySeriesId.putIfAbsent(
      seriesId,
      () => SeriesNarrativeSeed.generate(seriesId, firstName: firstName),
    );
  }

  StoryWorld getOrCreateStoryWorld({
    required UserModel user,
    required ChildProfile child,
  }) {
    final existing = _storyWorldByChildId[child.id];
    if (existing != null) return existing;
    final w = StoryWorldSeed.initial(child: child, user: user);
    _storyWorldByChildId[child.id] = w;
    return w;
  }

  void putStoryWorld(StoryWorld world) {
    _storyWorldByChildId[world.childId] = world;
  }

  void putMemorySnapshot(StoryMemorySnapshot snapshot) {
    _memorySnapshots.removeWhere((e) => e.storyId == snapshot.storyId);
    _memorySnapshots.add(snapshot);
  }

  void removeMemorySnapshotForStory(String storyId) {
    _memorySnapshots.removeWhere((e) => e.storyId == storyId);
  }

  List<StoryMemorySnapshot> recentMemorySnapshots(
    String childId, {
    int limit = 3,
  }) {
    final list = _memorySnapshots.where((e) => e.childId == childId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (list.length <= limit) return list;
    return list.sublist(0, limit);
  }

  void clearStories() {
    _storyByChildAndDateKey.clear();
    _seriesAnchorDateKeyByChildId.clear();
    _seriesNarrativeBySeriesId.clear();
    _storyWorldByChildId.clear();
    _memorySnapshots.clear();
  }

  void clearAll() {
    sessionUser = null;
    childProfile = null;
    subscription = null;
    clearStories();
  }
}
