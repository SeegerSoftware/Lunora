import '../../shared/models/enums/story_format.dart';
import '../../shared/models/enums/story_tone.dart';
import '../../shared/models/enums/universe_type.dart';
import '../../shared/models/series_state.dart';
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
    final likedThemes = child.preferredThemes.where((e) => e.trim().isNotEmpty).toList();
    final primaryTheme = likedThemes.isEmpty ? 'rêves étoilés' : likedThemes.first;
    final secondaryTheme = likedThemes.length > 1 ? likedThemes[1] : 'douce aventure';

    final title = isSerialized
        ? 'Les lanternes de $universe · chapitre $ch'
        : 'Une nuit douce pour $firstName';

    final content =
        '''
Ce soir du $dk, $firstName s’endort dans un monde $universe, baigné d’une lumière $toneLabel.
Les bruits du jour s’éloignent peu à peu, comme des vagues qui reculent doucement.

Dans cette histoire, $firstName retrouve deux repères qu’il/elle aime particulièrement :
$primaryTheme et $secondaryTheme. Chaque scène s’appuie sur ces thèmes pour rester familière
et rassurante.

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
        generationSource: 'fallback-safety',
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
      continuityUpdate: isSerialized
          ? ChapterContinuityUpdate(
              chapterSummary: summary,
              importantEvents: ['Un rituel du soir est consolidé'],
              charactersMet: [firstName],
              objectsIntroduced: ['Une lanterne douce'],
              resolvedLoops: ch >= request.totalChapters
                  ? ['La quête de sérénité est accomplie']
                  : const [],
              openLoops: ch < request.totalChapters
                  ? ['Découvrir un nouveau repère apaisant demain']
                  : const [],
              emotionalStep: 'Apaisement progressif',
              thingsToRemember: [
                '$firstName aime $primaryTheme',
                'Le ton reste calme et rassurant',
              ],
              thingsToAvoidRepeating: const [
                'Même ouverture mot pour mot',
                'Réintroduction des mêmes personnages',
              ],
              nextChapterGoal: ch < request.totalChapters
                  ? 'Approfondir la confiance du soir avec un élément nouveau'
                  : 'Clore en douceur toutes les boucles ouvertes',
            )
          : null,
      generationSource: 'fallback-mock',
    );
  }

  @override
  Future<SeriesBible> generateSeriesBible(StoryGenerationRequest request) async {
    final child = request.child;
    final theme = child.preferredThemes.isNotEmpty
        ? child.preferredThemes.first
        : 'douceur du soir';
    final total = request.totalChapters <= 0 ? 7 : request.totalChapters;
    final plan = List<ChapterPlanItem>.generate(total, (index) {
      final chapter = index + 1;
      final isLast = chapter == total;
      return ChapterPlanItem(
        chapterIndex: chapter,
        title: isLast
            ? 'Le soir des retrouvailles calmes'
            : 'Les petites lanternes - chapitre $chapter',
        goal: isLast
            ? 'Clore les boucles ouvertes avec douceur'
            : 'Faire progresser la quête calme autour de $theme',
        emotionalStep: isLast
            ? 'Sentiment de sécurité profonde'
            : 'Confiance qui grandit',
        newElement: isLast
            ? 'Un rituel final à garder'
            : 'Un nouveau repère familier',
        openLoop: isLast ? '' : 'Comment rendre la nuit encore plus sereine ?',
      );
    });

    return SeriesBible(
      seriesTitle: 'Les soirs paisibles de ${child.firstName}',
      pitch: 'Une série douce où chaque soir apporte un petit pas vers le calme.',
      universe: child.preferredUniverse.isEmpty
          ? child.universeType.displayLabel
          : child.preferredUniverse,
      tone: child.preferredTone.displayLabel,
      mainCharacters: [child.firstName],
      secondaryCharacters: child.familiarElements.isEmpty
          ? const ['Un petit guide lumineux']
          : child.familiarElements,
      recurringPlaces: const ['La chambre apaisée', 'Le sentier des étoiles'],
      storyArc: 'Installer une routine rassurante et confiante avant le sommeil.',
      emotionalArc: 'De la détente vers un sentiment stable de sécurité.',
      chapterPlan: plan,
      continuityRules: const [
        'Préserver les repères installés',
        'Ne pas réintroduire comme nouveau un personnage déjà connu',
      ],
      antiRepetitionRules: const [
        'Varier l’ouverture et les images sensorielles',
        'Introduire un nouvel élément par chapitre',
      ],
      plannedEnding: 'Une clôture douce qui remercie les compagnons et apaise.',
    );
  }
}
