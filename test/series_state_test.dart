import 'package:flutter_test/flutter_test.dart';
import 'package:elunai_v00/shared/models/series_state.dart';

void main() {
  test('SeriesBible accepts structured narrative fields from the backend', () {
    final bible = SeriesBible.fromMap({
      'seriesTitle': {'title': 'Les lumieres du soir'},
      'pitch': {'description': 'Une aventure calme.'},
      'universe': {'name': 'La foret douce'},
      'tone': 'reassuring',
      'mainCharacters': [
        {'name': 'Lina', 'description': 'Curieuse'},
        {'name': 'Nova'},
      ],
      'secondaryCharacters': const ['La lune'],
      'recurringPlaces': [
        {'name': 'La clairiere'},
      ],
      'storyArc': {'summary': 'Retrouver une lumiere.'},
      'emotionalArc': {'description': 'De la curiosite au calme.'},
      'chapterPlan': [
        {
          'chapterIndex': 1,
          'title': {'title': 'La premiere lueur'},
          'goal': {'description': 'Trouver le chemin.'},
          'emotionalStep': {'label': 'Confiance'},
          'newElement': {'name': 'Une lanterne'},
          'openLoop': {'summary': 'Qui veille dans la foret ?'},
        },
      ],
      'continuityRules': [
        {'description': 'Rester doux'},
      ],
      'antiRepetitionRules': const ['Varier les lieux'],
      'plannedEnding': {'description': 'Un coucher paisible.'},
    });

    expect(bible.seriesTitle, 'Les lumieres du soir');
    expect(bible.pitch, 'Une aventure calme.');
    expect(bible.mainCharacters, ['Lina', 'Nova']);
    expect(bible.recurringPlaces, ['La clairiere']);
    expect(bible.chapterPlan.single.title, 'La premiere lueur');
    expect(bible.chapterPlan.single.goal, 'Trouver le chemin.');
    expect(bible.continuityRules, ['Rester doux']);
    expect(bible.plannedEnding, 'Un coucher paisible.');
  });

  test('ChapterContinuityUpdate accepts structured lists', () {
    final update = ChapterContinuityUpdate.fromMap({
      'chapterSummary': {'summary': 'Une etape terminee.'},
      'importantEvents': [
        {'description': 'Lina trouve la lanterne'},
      ],
      'charactersMet': [
        {'name': 'Nova'},
      ],
      'objectsIntroduced': [
        {'name': 'La lanterne'},
      ],
      'resolvedLoops': const [],
      'openLoops': [
        {'summary': 'Ou mene le sentier ?'},
      ],
      'emotionalStep': {'label': 'Apaisement'},
      'thingsToRemember': const ['La lanterne rassure'],
      'thingsToAvoidRepeating': const [],
      'nextChapterGoal': {'goal': 'Suivre le sentier.'},
    });

    expect(update.chapterSummary, 'Une etape terminee.');
    expect(update.importantEvents, ['Lina trouve la lanterne']);
    expect(update.charactersMet, ['Nova']);
    expect(update.objectsIntroduced, ['La lanterne']);
    expect(update.openLoops, ['Ou mene le sentier ?']);
    expect(update.nextChapterGoal, 'Suivre le sentier.');
  });
}
