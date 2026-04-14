import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/ai_generation_config.dart';
import '../config/backend_config.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/data/mock_auth_repository.dart';
import '../../features/child_profile/data/child_profile_repository.dart';
import '../../features/child_profile/data/firebase_child_profile_repository.dart';
import '../../features/child_profile/data/mock_child_profile_repository.dart';
import '../../features/stories/data/firebase_story_repository.dart';
import '../../features/stories/data/mock_story_repository.dart';
import '../../features/stories/data/story_repository.dart';
import '../../features/story_memory/data/firebase_story_memory_repository.dart';
import '../../features/story_memory/data/mock_story_memory_repository.dart';
import '../../features/story_memory/data/story_memory_repository.dart';
import '../../features/subscription/data/firebase_subscription_repository.dart';
import '../../features/subscription/data/mock_subscription_repository.dart';
import '../../features/subscription/data/subscription_repository.dart';
import '../../services/mock/lunora_mock_store.dart';
import '../../services/story_generation/ai_story_generation_service.dart';
import '../../services/story_generation/mock_story_generation_service.dart';
import '../../services/story_generation/openai_chat_client.dart';
import '../../services/story_generation/story_generation_service.dart';

final lunoraMockStoreProvider = Provider<LunoraMockStore>((ref) {
  return LunoraMockStore();
});

final storyGenerationServiceProvider = Provider<StoryGenerationService>((ref) {
  final mock = MockStoryGenerationService();
  if (!AiGenerationConfig.canUseRemoteAi) {
    return mock;
  }
  final client = OpenAiChatClient();
  ref.onDispose(client.close);
  return AiStoryGenerationService(client: client, fallback: mock);
});

final storyMemoryRepositoryProvider = Provider<StoryMemoryRepository>((ref) {
  if (BackendConfig.useFirebase) {
    return FirebaseStoryMemoryRepository();
  }
  final store = ref.watch(lunoraMockStoreProvider);
  return MockStoryMemoryRepository(store: store);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (BackendConfig.useFirebase) {
    return FirebaseAuthRepository();
  }
  final store = ref.watch(lunoraMockStoreProvider);
  return MockAuthRepository(store: store);
});

final childProfileRepositoryProvider = Provider<ChildProfileRepository>((ref) {
  if (BackendConfig.useFirebase) {
    return FirebaseChildProfileRepository();
  }
  final store = ref.watch(lunoraMockStoreProvider);
  return MockChildProfileRepository(store: store);
});

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  final generation = ref.watch(storyGenerationServiceProvider);
  final memory = ref.watch(storyMemoryRepositoryProvider);
  if (BackendConfig.useFirebase) {
    return FirebaseStoryRepository(
      generationService: generation,
      memoryRepository: memory,
    );
  }
  final store = ref.watch(lunoraMockStoreProvider);
  return MockStoryRepository(
    store: store,
    generationService: generation,
    memoryRepository: memory,
  );
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  if (BackendConfig.useFirebase) {
    return FirebaseSubscriptionRepository();
  }
  final store = ref.watch(lunoraMockStoreProvider);
  return MockSubscriptionRepository(store: store);
});
