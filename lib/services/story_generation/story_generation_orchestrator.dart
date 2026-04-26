import 'dart:developer' as developer;

import '../../core/config/ai_generation_config.dart';
import 'models/story_generation_request.dart';
import 'models/story_generation_result.dart';
import 'openai_chat_client.dart';
import 'story_generation_json.dart';
import 'story_prompt_builder.dart';
import 'story_quality_result.dart';
import 'story_quality_validator.dart';

/// Entrée orchestrateur : repose sur [StoryGenerationRequest] (profil enfant + contexte).
final class StoryBrief {
  const StoryBrief(this.request);

  final StoryGenerationRequest request;
}

/// Génère avec le modèle économique, score en local, puis [gpt-4o] seulement si besoin.
class StoryGenerationOrchestrator {
  StoryGenerationOrchestrator({
    required OpenAiChatClient chatClient,
    StoryPromptBuilder promptBuilder = const StoryPromptBuilder(),
    StoryQualityValidator qualityValidator = const StoryQualityValidator(),
    String? miniModel,
    String? premiumModel,
    this.regenerateMiniWhenScoreBelow50 = true,
  })  : _client = chatClient,
        _promptBuilder = promptBuilder,
        _qualityValidator = qualityValidator,
        _miniModel = (miniModel ?? AiGenerationConfig.openaiModelPremium).trim(),
        _premiumModel =
            (premiumModel ?? AiGenerationConfig.openaiModelPremium).trim();

  final OpenAiChatClient _client;
  final StoryPromptBuilder _promptBuilder;
  final StoryQualityValidator _qualityValidator;
  final String _miniModel;
  final String _premiumModel;

  /// Si le premier score mini est sous 50, une 2e génération mini peut améliorer sans coût premium.
  final bool regenerateMiniWhenScoreBelow50;

  /// 1) mini, score, OK si au moins 70.
  /// 2) si score sous 50 et option : 2e mini, on garde le meilleur des deux.
  /// 3) si toujours sous 70 : un seul appel premium, puis meilleur score mini vs premium.
  Future<StoryGenerationResult> generate(StoryBrief brief) async {
    final request = brief.request;
    final system = _promptBuilder.buildSystemPreamble();
    final baseUser = _promptBuilder.buildUserPrompt(request);
    final childName = request.child.firstName;
    final targetMinutes = request.child.storyLengthMinutes;

    StoryGenerationResult best;
    try {
      best = await _generateWithLengthRetries(
        system: system,
        baseUser: baseUser,
        request: request,
        model: _miniModel,
      );
    } on FormatException catch (e) {
      if (!_isLengthTooShortError(e)) rethrow;
      developer.log(
        'mini model too short, forcing premium escalation: ${e.message}',
        name: 'elunai.ai.quality',
      );
      final premiumForced = await _generateWithLengthRetries(
        system: system,
        baseUser: baseUser,
        request: request,
        model: _premiumModel,
        mandatoryHint: _premiumLengthEscalationHint(e.message),
      );
      return premiumForced.copyWith(generationSource: 'remote-ai-gpt-4o');
    }
    var bestQ = _evaluate(best, childName, targetMinutes);
    _logStage('mini-1', _miniModel, bestQ);

    if (bestQ.isValid) {
      return best.copyWith(generationSource: 'remote-ai-mini');
    }

    if (regenerateMiniWhenScoreBelow50 && bestQ.score < 50) {
      final second = await _generateWithLengthRetries(
        system: system,
        baseUser: baseUser,
        request: request,
        model: _miniModel,
      );
      final q2 = _evaluate(second, childName, targetMinutes);
      _logStage('mini-2', _miniModel, q2);
      if (q2.score > bestQ.score) {
        best = second;
        bestQ = q2;
      }
      if (bestQ.isValid) {
        return best.copyWith(generationSource: 'remote-ai-mini');
      }
    }

    if (bestQ.score >= StoryQualityValidator.validThreshold) {
      return best.copyWith(generationSource: 'remote-ai-mini');
    }

    final premium = await _generateWithLengthRetries(
      system: system,
      baseUser: baseUser,
      request: request,
      model: _premiumModel,
      mandatoryHint: _premiumLengthEscalationHint(null),
    );
    final qPremium = _evaluate(premium, childName, targetMinutes);
    _logStage('premium', _premiumModel, qPremium);

    if (qPremium.score > bestQ.score) {
      return premium.copyWith(generationSource: 'remote-ai-gpt-4o');
    }
    return best.copyWith(generationSource: 'remote-ai-mini');
  }

  StoryQualityResult _evaluate(
    StoryGenerationResult result,
    String childName,
    int targetMinutes,
  ) {
    final story = '${result.title}\n\n${result.content}';
    return _qualityValidator.evaluate(
      story: story,
      childName: childName,
      targetMinutes: targetMinutes,
    );
  }

  void _logStage(String stage, String model, StoryQualityResult q) {
    developer.log(
      'quality score=$model stage=$stage total=${q.score} '
      'L=${q.lengthPoints} N=${q.namePoints} S=${q.structurePoints} '
      'F=${q.fluencyPoints} T=${q.tonePoints} E=${q.endingPoints} '
      'NR=${q.narrativePoints} P=${q.profilePoints} '
      'guard=${q.narrativeGuardPassed} valid=${q.isValid}',
      name: 'elunai.ai.quality',
    );
  }

  Future<StoryGenerationResult> _generateWithLengthRetries({
    required String system,
    required String baseUser,
    required StoryGenerationRequest request,
    required String model,
    String? mandatoryHint,
  }) async {
    StoryGenerationResult? result;
    Object? lastLengthError;

    for (var attempt = 1; attempt <= 3; attempt++) {
      final retryHint = attempt == 1
          ? ''
          : '''

==================================================
REESSAI OBLIGATOIRE (LONGUEUR INSUFFISANTE)
==================================================
Ta reponse precedente etait trop courte.
- etends nettement le champ "content"
- ajoute des scenes douces et fluides (pas de repetition artificielle)
- respecte strictement une longueur elevee en mots
- conserve strictement le meme format JSON attendu
''';
      final user = '$baseUser${mandatoryHint ?? ''}$retryHint';

      final raw = await _client.completeJsonChat(
        systemMessage: system,
        userMessage: user,
        modelOverride: model,
      );

      final map = StoryGenerationJsonParser.extractObject(raw);
      final parsed = StoryGenerationJsonParser.parseMap(map);

      try {
        result = StoryGenerationResultNormalizer.normalize(
          parsed: parsed,
          request: request,
        );
        break;
      } on FormatException catch (e) {
        final isTooShort = e.message.contains('content trop court');
        if (!isTooShort || attempt == 3) rethrow;
        lastLengthError = e;
      }
    }

    if (result == null) {
      throw lastLengthError ??
          const FormatException('Generation invalide: resultat manquant');
    }
    return result;
  }

  bool _isLengthTooShortError(FormatException e) {
    return e.message.contains('content trop court');
  }

  String _premiumLengthEscalationHint(String? previousErrorMessage) {
    final minFromError = previousErrorMessage == null
        ? null
        : RegExp(r'min dur (\d+)').firstMatch(previousErrorMessage)?.group(1);
    final hardMinLine = minFromError == null
        ? '- ne rends jamais une version courte: longueur premium obligatoire'
        : '- longueur minimale obligatoire: au moins $minFromError mots dans "content"';

    return '''

==================================================
ESCALADE PREMIUM OBLIGATOIRE
==================================================
Le draft precedent etait insuffisant en longueur.
$hardMinLine
- si besoin, ajoute des scenes douces supplementaires pour atteindre la longueur
- n abrege jamais la fin: garde la descente vers le sommeil complete
''';
  }
}
