import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/backend_config.dart';
import '../config/mobile_api_config.dart';
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
import '../../services/backend/elunai_api_client.dart';
import '../../services/story_generation/backend_story_generation_service.dart';
import '../../services/story_generation/models/story_generation_request.dart';
import '../../services/story_generation/models/story_generation_result.dart';
import '../../services/story_generation/story_generation_exception.dart';
import '../../services/story_generation/story_generation_service.dart';

void _requireFirebase() {
  if (!BackendConfig.useFirebase) {
    throw StateError(
      'Elunai est conçu pour fonctionner en ligne avec Firebase. '
      'Lance l’app avec USE_FIREBASE=true (voir dart_defines.example.json).',
    );
  }
}

final elunaiApiClientProvider = Provider<ElunaiApiClient>((ref) {
  final client = MobileApiConfig.isConfigured
      ? ElunaiApiClient()
      : ElunaiApiClient(baseUrl: '');
  ref.onDispose(client.close);
  return client;
});

final storyGenerationServiceProvider = Provider<StoryGenerationService>((ref) {
  if (MobileApiConfig.isConfigured) {
    return BackendStoryGenerationService(
      apiClient: ref.watch(elunaiApiClientProvider),
    );
  }
  return _UnconfiguredStoryGenerationService();
});

final class _UnconfiguredStoryGenerationService
    implements StoryGenerationService {
  @override
  Future<StoryGenerationResult> generate(StoryGenerationRequest request) async {
    throw StoryGenerationException(
      'Génération en ligne désactivée : configure USE_SERVER_API=true et '
      'ELUNAI_API_BASE_URL pour utiliser le backend Elunai.',
    );
  }

  @override
  Future<SeriesBible> generateSeriesBible(
    StoryGenerationRequest request,
  ) async {
    throw StoryGenerationException(
      'Génération en ligne désactivée : configure le backend Elunai.',
    );
  }
}

final storyMemoryRepositoryProvider = Provider<StoryMemoryRepository>((ref) {
  _requireFirebase();
  return FirebaseStoryMemoryRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  _requireFirebase();
  return FirebaseAuthRepository(apiClient: ref.watch(elunaiApiClientProvider));
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
