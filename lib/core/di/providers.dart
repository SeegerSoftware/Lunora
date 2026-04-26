import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/ai_generation_config.dart';
import '../config/backend_config.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/child_profile/data/child_profile_repository.dart';
import '../../features/child_profile/data/firebase_child_profile_repository.dart';
import '../../features/stories/data/firebase_story_repository.dart';
import '../../features/stories/data/story_repository.dart';
import '../../features/story_memory/data/firebase_story_memory_repository.dart';
import '../../features/story_memory/data/story_memory_repository.dart';
import '../../features/subscription/data/firebase_subscription_repository.dart';
import '../../features/subscription/data/subscription_repository.dart';
import '../../shared/models/series_state.dart';
import '../../services/story_generation/ai_story_generation_service.dart';
import '../../services/story_generation/models/story_generation_request.dart';
import '../../services/story_generation/models/story_generation_result.dart';
import '../../services/story_generation/openai_chat_client.dart';
import '../../services/story_generation/story_generation_exception.dart';
import '../../services/story_generation/story_generation_orchestrator.dart';
import '../../services/story_generation/story_generation_service.dart';

void _requireFirebase() {
  if (!BackendConfig.useFirebase) {
    throw StateError(
      'Lunora est conçu pour fonctionner en ligne avec Firebase. '
      'Lance l’app avec USE_FIREBASE=true (voir dart_defines.example.json).',
    );
  }
}

final storyGenerationServiceProvider = Provider<StoryGenerationService>((ref) {
  if (!AiGenerationConfig.canUseRemoteAi) {
    return _UnconfiguredStoryGenerationService();
  }
  final client = OpenAiChatClient();
  ref.onDispose(client.close);
  final orchestrator = StoryGenerationOrchestrator(chatClient: client);
  return AiStoryGenerationService(
    orchestrator: orchestrator,
    chatClient: client,
  );
});

final class _UnconfiguredStoryGenerationService implements StoryGenerationService {
  @override
  Future<StoryGenerationResult> generate(StoryGenerationRequest request) async {
    throw StoryGenerationException(
      'Génération en ligne désactivée : ajoute USE_REAL_AI=true et une clé OPENAI_API_KEY '
      'dans dart_defines.json (voir dart_defines.example.json).',
    );
  }

  @override
  Future<SeriesBible> generateSeriesBible(StoryGenerationRequest request) async {
    throw StoryGenerationException(
      'Génération en ligne désactivée : configure OPENAI_API_KEY et USE_REAL_AI.',
    );
  }
}

final storyMemoryRepositoryProvider = Provider<StoryMemoryRepository>((ref) {
  _requireFirebase();
  return FirebaseStoryMemoryRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  _requireFirebase();
  return FirebaseAuthRepository();
});

final childProfileRepositoryProvider = Provider<ChildProfileRepository>((ref) {
  _requireFirebase();
  return FirebaseChildProfileRepository();
});

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  _requireFirebase();
  final generation = ref.watch(storyGenerationServiceProvider);
  final memory = ref.watch(storyMemoryRepositoryProvider);
  return FirebaseStoryRepository(
    generationService: generation,
    memoryRepository: memory,
  );
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  _requireFirebase();
  return FirebaseSubscriptionRepository();
});
