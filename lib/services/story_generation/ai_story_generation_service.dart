import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../core/config/ai_generation_config.dart';
import '../../shared/models/series_state.dart';
import 'content_safety_policy.dart';
import 'models/story_generation_request.dart';
import 'models/story_generation_result.dart';
import 'openai_chat_client.dart';
import 'story_generation_orchestrator.dart';
import 'story_generation_service.dart';
import 'story_prompt_builder.dart';
import 'story_generation_json.dart';

/// Génération via LLM (mini + secours qualité premium) avec repli sur [fallback].
class AiStoryGenerationService implements StoryGenerationService {
  AiStoryGenerationService({
    required StoryGenerationOrchestrator orchestrator,
    required OpenAiChatClient chatClient,
    required StoryGenerationService fallback,
    ContentSafetyPolicy safetyPolicy = const LocalContentSafetyPolicy(),
    StoryPromptBuilder promptBuilder = const StoryPromptBuilder(),
  })  : _orchestrator = orchestrator,
        _chatClient = chatClient,
        _fallback = fallback,
        _safetyPolicy = safetyPolicy,
        _promptBuilder = promptBuilder;

  final StoryGenerationOrchestrator _orchestrator;
  final OpenAiChatClient _chatClient;
  final StoryGenerationService _fallback;
  final ContentSafetyPolicy _safetyPolicy;
  final StoryPromptBuilder _promptBuilder;

  @override
  Future<StoryGenerationResult> generate(StoryGenerationRequest request) async {
    if (!AiGenerationConfig.canUseRemoteAi) {
      final fallback = await _fallback.generate(request);
      return fallback.copyWith(generationSource: 'fallback-config');
    }

    try {
      final result = await _orchestrator.generate(StoryBrief(request));

      final draft = StoryGenerationDraft(
        title: result.title,
        content: result.content,
        summary: result.summary,
      );

      if (!_safetyPolicy.assertChildFriendly(profile: request.child, draft: draft)) {
        developer.log(
          'AiStoryGeneration: safety policy rejected output, using fallback',
          name: 'elunai.ai',
        );
        final fallback = await _fallback.generate(request);
        return fallback.copyWith(generationSource: 'fallback-safety');
      }

      return result;
    } catch (e, st) {
      developer.log(
        'AiStoryGeneration: $e',
        name: 'elunai.ai',
        error: e,
        stackTrace: st,
      );
      if (kDebugMode) {
        debugPrint('AiStoryGenerationService fallback: $e');
      }
      final fallback = await _fallback.generate(request);
      return fallback.copyWith(generationSource: 'fallback-error');
    }
  }

  @override
  Future<SeriesBible> generateSeriesBible(StoryGenerationRequest request) async {
    if (!AiGenerationConfig.canUseRemoteAi) {
      return _fallback.generateSeriesBible(request);
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
      developer.log(
        'AiSeriesBibleGeneration: $e',
        name: 'elunai.ai',
        error: e,
        stackTrace: st,
      );
      return _fallback.generateSeriesBible(request);
    }
  }
}
