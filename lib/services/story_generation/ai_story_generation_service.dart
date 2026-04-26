import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../core/config/ai_generation_config.dart';
import '../../core/validation/story_profile_moderation.dart';
import '../../shared/models/series_state.dart';
import 'content_safety_policy.dart';
import 'models/story_generation_request.dart';
import 'models/story_generation_result.dart';
import 'openai_chat_client.dart';
import 'story_generation_exception.dart';
import 'story_generation_json.dart';
import 'story_generation_orchestrator.dart';
import 'story_generation_service.dart';
import 'story_prompt_builder.dart';

/// Génération via LLM (mini + secours qualité premium). Hors ligne de secours mock :
/// les échecs remontent [StoryGenerationException] avec un message explicite.
class AiStoryGenerationService implements StoryGenerationService {
  AiStoryGenerationService({
    required StoryGenerationOrchestrator orchestrator,
    required OpenAiChatClient chatClient,
    ContentSafetyPolicy safetyPolicy = const LocalContentSafetyPolicy(),
    StoryPromptBuilder promptBuilder = const StoryPromptBuilder(),
  })  : _orchestrator = orchestrator,
        _chatClient = chatClient,
        _safetyPolicy = safetyPolicy,
        _promptBuilder = promptBuilder;

  final StoryGenerationOrchestrator _orchestrator;
  final OpenAiChatClient _chatClient;
  final ContentSafetyPolicy _safetyPolicy;
  final StoryPromptBuilder _promptBuilder;

  @override
  Future<StoryGenerationResult> generate(StoryGenerationRequest request) async {
    if (!AiGenerationConfig.canUseRemoteAi) {
      throw StoryGenerationException(
        'Génération impossible : la clé OpenAI ou USE_REAL_AI est absente. '
        'Copie dart_defines.example.json vers dart_defines.json et renseigne OPENAI_API_KEY.',
      );
    }

    final profileMod = StoryProfileModeration.validateChildProfile(request.child);
    if (profileMod != null) {
      developer.log(
        'AiStoryGeneration: profil rejeté ($profileMod)',
        name: 'elunai.ai',
      );
      throw StoryGenerationException(profileMod);
    }

    try {
      final result = await _orchestrator.generate(StoryBrief(request));

      final draft = StoryGenerationDraft(
        title: result.title,
        content: result.content,
        summary: result.summary,
      );

      if (!_safetyPolicy.assertChildFriendly(profile: request.child, draft: draft)) {
        throw StoryGenerationException(
          'L’histoire générée ne respecte pas les règles pour enfants ou les préférences '
          'indiquées par les parents. Tu peux reformuler le profil ou réessayer plus tard.',
        );
      }

      return result;
    } catch (e, st) {
      if (e is StoryGenerationException) rethrow;
      developer.log(
        'AiStoryGeneration: $e',
        name: 'elunai.ai',
        error: e,
        stackTrace: st,
      );
      if (kDebugMode) {
        debugPrint('AiStoryGenerationService: $e');
      }
      throw StoryGenerationException(
        'La génération d’histoire a échoué. Détail technique : ${e.toString()}',
      );
    }
  }

  @override
  Future<SeriesBible> generateSeriesBible(StoryGenerationRequest request) async {
    if (!AiGenerationConfig.canUseRemoteAi) {
      throw StoryGenerationException(
        'Bible de série indisponible : configure OPENAI_API_KEY et USE_REAL_AI.',
      );
    }
    final bibleProfileErr = StoryProfileModeration.validateChildProfile(request.child);
    if (bibleProfileErr != null) {
      throw StoryGenerationException(bibleProfileErr);
    }
    try {
      final system = _promptBuilder.buildSystemPreamble();
      final user = _promptBuilder.buildSeriesBiblePrompt(request);
      final raw = await _chatClient.completeJsonChat(
        systemMessage: system,
        userMessage: user,
      );
      final obj = StoryGenerationJsonParser.extractObject(raw);
      return SeriesBible.fromMap(obj);
    } catch (e, st) {
      if (e is StoryGenerationException) rethrow;
      developer.log(
        'AiSeriesBibleGeneration: $e',
        name: 'elunai.ai',
        error: e,
        stackTrace: st,
      );
      throw StoryGenerationException(
        'La bible de série n’a pas pu être générée. Détail : ${e.toString()}',
      );
    }
  }
}
