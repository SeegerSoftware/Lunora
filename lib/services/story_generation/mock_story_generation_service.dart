import '../../shared/models/enums/story_format.dart';
import '../../shared/models/enums/story_tone.dart';
import '../../shared/models/enums/universe_type.dart';
import 'content_safety_policy.dart';
import 'models/story_generation_request.dart';
import 'models/story_generation_result.dart';
import 'story_generation_service.dart';
import 'story_prompt_builder.dart';

class MockStoryGenerationService implements StoryGenerationService {
  MockStoryGenerationService({
    StoryPromptBuilder promptBuilder = const StoryPromptBuilder(),
    ContentSafetyPolicy safetyPolicy = const LocalContentSafetyPolicy(),
  }) : _promptBuilder = promptBuilder,
       _safetyPolicy = safetyPolicy;

  final StoryPromptBuilder _promptBuilder;
  final ContentSafetyPolicy _safetyPolicy;

  @override
  Future<StoryGenerationResult> generate(StoryGenerationRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));

    final child = request.child;
    final isSerialized = child.storyFormat == StoryFormat.serializedChapters;
    final seriesId = isSerialized
        ? (request.seriesId ?? 'series_${child.id}')
        : null;

    final universe = child.universeType.displayLabel.toLowerCase();
    final toneLabel = child.preferredTone.displayLabel.toLowerCase();

    final firstName = child.firstName;
    final dk = request.dateKey;
    final ch = request.chapterIndex;

    final title = isSerialized
        ? 'Les lanternes de $universe · chapitre $ch'
        : 'Une nuit douce pour $firstName';

    final content =
        '''
Ce soir du $dk, $firstName s’endort dans un monde $universe, baigné d’une lumière $toneLabel.
Les bruits du jour s’éloignent peu à peu, comme des vagues qui reculent doucement.

Un petit rite commence : trois respirations lentes, les mains posées sur le cœur,
et l’idée que demain sera accueilli avec calme. Les pensées s’alignent comme des étoiles patientes,
chacune à sa place, sans se presser.

Au loin, une voix chaleureuse — la tienne — raconte que tout est déjà assez pour ce soir :
les efforts, les rires, les petites inquiétudes… tout peut attendre au bord du lit, posé sur une étagère imaginaire.

$firstName sent le cocon du ciel tout près : une couverture légère, une chambre apaisée,
et la certitude simple que l’amour reste là, même quand les paupières deviennent lourdes.

La journée referme son livre. Il ne reste qu’une page blanche pour rêver,
et une fin douce : « Dors bien, tout est tranquille. »

— Repère du calendrier : $dk · chapitre $ch sur ${request.totalChapters}.
'''
            .trim();

    final summary =
        'Un rituel du soir apaisant dans un univers $universe, pour glisser vers le sommeil en confiance.';

    final draft = StoryGenerationDraft(
      title: title,
      content: content,
      summary: summary,
    );

    final safe = _safetyPolicy.assertChildFriendly(
      profile: child,
      draft: draft,
    );

    if (!safe) {
      return StoryGenerationResult(
        title: 'Un ciel tout doux pour $firstName',
        content:
            'Il existe un endroit tout simple où le soir devient chaud comme une couverture. '
            '$firstName y marche sans effort, le cœur tranquille, jusqu’au moment où les paupières se ferment, '
            'et où le sommeil arrive comme un ami silencieux. Demain pourra attendre : ce soir, tout est calme, tout est doux.\n\n'
            '— $dk · chapitre $ch.',
        summary: 'Version de secours apaisante et universelle.',
        themeLabel: 'Douceur du coucher',
        tone: StoryTone.reassuring,
        estimatedReadingMinutes: child.storyLengthMinutes,
        format: child.storyFormat,
        chapterNumber: request.chapterIndex,
        totalChapters: request.totalChapters,
        seriesId: seriesId,
      );
    }

    _promptBuilder.buildSystemPreamble();
    _promptBuilder.buildUserPrompt(request);

    return StoryGenerationResult(
      title: title,
      content: content,
      summary: summary,
      themeLabel: child.preferredThemes.isNotEmpty
          ? child.preferredThemes.first
          : 'Rituel du soir',
      tone: child.preferredTone,
      estimatedReadingMinutes: child.storyLengthMinutes,
      format: child.storyFormat,
      chapterNumber: request.chapterIndex,
      totalChapters: request.totalChapters,
      seriesId: seriesId,
    );
  }
}
