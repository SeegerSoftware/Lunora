import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../core/config/ai_generation_config.dart';
import 'content_safety_policy.dart';
import 'models/story_generation_request.dart';
import 'models/story_generation_result.dart';
import 'openai_chat_client.dart';
import 'story_generation_json.dart';
import 'story_generation_service.dart';
import 'story_prompt_builder.dart';

/// Génération via LLM (OpenAI Chat Completions JSON) avec repli sur [fallback].
class AiStoryGenerationService implements StoryGenerationService {
  AiStoryGenerationService({
    required OpenAiChatClient client,
    required StoryGenerationService fallback,
    StoryPromptBuilder promptBuilder = const StoryPromptBuilder(),
    ContentSafetyPolicy safetyPolicy = const LocalContentSafetyPolicy(),
  })  : _client = client,
        _fallback = fallback,
        _promptBuilder = promptBuilder,
        _safetyPolicy = safetyPolicy;

  final OpenAiChatClient _client;
  final StoryGenerationService _fallback;
  final StoryPromptBuilder _promptBuilder;
  final ContentSafetyPolicy _safetyPolicy;

  @override
  Future<StoryGenerationResult> generate(StoryGenerationRequest request) async {
    if (!AiGenerationConfig.canUseRemoteAi) {
      final fallback = await _fallback.generate(request);
      return fallback.copyWith(generationSource: 'fallback-config');
    }

    try {
      final system = _promptBuilder.buildSystemPreamble();
      final user = _promptBuilder.buildUserPrompt(request);

      final raw = await _client.completeJsonChat(
        systemMessage: system,
        userMessage: user,
      );

      final map = StoryGenerationJsonParser.extractObject(raw);
      final parsed = StoryGenerationJsonParser.parseMap(map);
      final result = StoryGenerationResultNormalizer.normalize(
        parsed: parsed,
        request: request,
      );

      final draft = StoryGenerationDraft(
        title: result.title,
        content: result.content,
        summary: result.summary,
      );

      if (!_safetyPolicy.assertChildFriendly(profile: request.child, draft: draft)) {
        developer.log(
          'AiStoryGeneration: safety policy rejected output, using fallback',
          name: 'lunora.ai',
        );
        final fallback = await _fallback.generate(request);
        return fallback.copyWith(generationSource: 'fallback-safety');
      }

      return result;
    } catch (e, st) {
      developer.log(
        'AiStoryGeneration: $e',
        name: 'lunora.ai',
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
}
