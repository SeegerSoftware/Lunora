import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../core/utils/age_calculator.dart';
import '../../features/story_memory/domain/story_memory_context.dart';
import '../../shared/models/enums/story_format.dart';
import '../../shared/models/enums/story_tone.dart';
import '../../shared/models/series_state.dart';
import '../../shared/models/story_universe.dart';
import '../backend/elunai_api_client.dart';
import 'models/story_generation_request.dart';
import 'models/story_generation_result.dart';
import 'story_generation_exception.dart';
import 'story_generation_json.dart';
import 'story_generation_service.dart';

class BackendStoryGenerationService implements StoryGenerationService {
  BackendStoryGenerationService({
    required ElunaiApiClient apiClient,
    firebase_auth.FirebaseAuth? firebaseAuth,
  })  : _api = apiClient,
        _auth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  final ElunaiApiClient _api;
  final firebase_auth.FirebaseAuth _auth;

  @override
  Future<StoryGenerationResult> generate(StoryGenerationRequest request) async {
    final response = await _postGeneration(kind: 'story', request: request);
    final result = response['result'];
    if (result is! Map) {
      throw StoryGenerationException('Réponse backend invalide: result manquant.');
    }
    final parsed = StoryGenerationJsonParser.parseMap(
      Map<String, dynamic>.from(result),
    );
    return StoryGenerationResultNormalizer.normalize(
      parsed: parsed,
      request: request,
    ).copyWith(generationSource: 'backend-openai');
  }

  @override
  Future<SeriesBible> generateSeriesBible(StoryGenerationRequest request) async {
    final response = await _postGeneration(
      kind: 'series_bible',
      request: request,
    );
    final result = response['result'];
    if (result is! Map) {
      throw StoryGenerationException('Réponse backend invalide: result manquant.');
    }
    return SeriesBible.fromMap(Map<String, dynamic>.from(result));
  }

  Future<Map<String, dynamic>> _postGeneration({
    required String kind,
    required StoryGenerationRequest request,
  }) async {
    if (!_api.isConfigured) {
      throw StoryGenerationException('Backend Elunai non configuré.');
    }
    final token = await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StoryGenerationException('Session Firebase requise.');
    }
    try {
      return await _api.postJson(
        '/stories/generate',
        bearerToken: token,
        body: _requestBody(kind: kind, request: request),
      );
    } catch (e) {
      throw StoryGenerationException('Génération backend impossible : $e');
    }
  }

  Map<String, dynamic> _requestBody({
    required String kind,
    required StoryGenerationRequest request,
  }) {
    final child = request.child;
    final memory = request.memoryContext;
    return {
      'kind': kind,
      'user': request.user.toMap(),
      'child': {
        ...child.toMap(),
        'preferredTone': child.preferredTone.wireValue,
        'storyFormat': child.storyFormat.wireValue,
        'universeType': child.storyUniverse.wireValue,
      },
      'dateKey': request.dateKey,
      'chapterIndex': request.chapterIndex,
      'totalChapters': request.totalChapters,
      'seriesId': request.seriesId,
      'continuityContext': request.continuityContext,
      'seriesFilRougeBlock': request.seriesFilRougeBlock,
      'ageYears': AgeCalculator.ageInYears(
        birthMonth: child.birthMonth,
        birthYear: child.birthYear,
      ),
      'memoryPromptBlock': memory?.buildPromptBlock(),
      'memoryContext': memory == null ? null : _memoryContextMap(memory),
      'seriesBible': request.seriesBible?.toMap(),
      'seriesState': request.seriesState?.toMap(),
      'currentChapterPlan': request.currentChapterPlan?.toMap(),
    };
  }

  Map<String, dynamic> _memoryContextMap(StoryMemoryContext memory) {
    return {
      'repetitionAvoidance': memory.repetitionAvoidance,
      'nextNarrativeIntent': memory.nextNarrativeIntent,
      'promptBlock': memory.buildPromptBlock(),
    };
  }
}
