import '../../shared/models/story.dart';

abstract interface class StoryIllustrationService {
  Future<void> enqueueGeneration(Story story);

  Future<void> regenerate(Story story);

  Future<String?> cachedCoverUrl(String storyId);
}

/// Public-store placeholder. Generation remains backend-only and can be
/// activated later without changing presentation code.
class DeferredStoryIllustrationService implements StoryIllustrationService {
  const DeferredStoryIllustrationService();

  @override
  Future<String?> cachedCoverUrl(String storyId) async => null;

  @override
  Future<void> enqueueGeneration(Story story) async {}

  @override
  Future<void> regenerate(Story story) async {}
}
