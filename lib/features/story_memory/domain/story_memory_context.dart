import 'package:equatable/equatable.dart';

import 'story_memory_snapshot.dart';
import 'story_world.dart';

/// Contexte non persisté passé au LLM (construit avant chaque génération).
class StoryMemoryContext extends Equatable {
  const StoryMemoryContext({
    required this.storyWorld,
    required this.recentSnapshots,
    required this.repetitionAvoidance,
    required this.nextNarrativeIntent,
  });

  final StoryWorld storyWorld;
  final List<StoryMemorySnapshot> recentSnapshots;
  final String repetitionAvoidance;
  final String nextNarrativeIntent;

  /// Bloc texte injecté dans le prompt utilisateur.
  String buildPromptBlock() {
    final w = storyWorld;
    final places = w.recurringPlaces.isEmpty
        ? '(à définir au fil des histoires)'
        : w.recurringPlaces.join(', ');
    final recent = recentSnapshots.isEmpty
        ? 'Aucun épisode récent en mémoire (première(s) histoire(s) ou mémoire vide).'
        : recentSnapshots.map(_formatSnapshotLine).join('\n');

    return '''
==================================================
MÉMOIRE LONG TERME (univers actif)
==================================================

Monde : « ${w.worldName} »
Compagnon récurrent : ${w.mainCompanion}
Objet spécial : ${w.magicItem}
Objectif global : ${w.coreGoal}
Lieux récurrents : $places
Ton du monde : ${w.worldTone}
Arc narratif en cours : ${w.currentArc}
Situation actuelle (dernier état connu) : ${w.currentState}

==================================================
MÉMOIRE RÉCENTE (derniers épisodes)
==================================================

$recent

Éléments déjà beaucoup utilisés (à varier avec créativité) :
$repetitionAvoidance

Intention pour ce soir :
$nextNarrativeIntent
'''
        .trim();
  }

  static String _formatSnapshotLine(StoryMemorySnapshot s) {
    final themes = s.usedThemes.isEmpty ? '—' : s.usedThemes.join(', ');
    final pl = s.usedPlaces.isEmpty ? '—' : s.usedPlaces.join(', ');
    final ch = s.usedCharacters.isEmpty ? '—' : s.usedCharacters.join(', ');
    return '- ${s.dateKey} · ${s.summaryShort}\n  Thèmes / lieux / figures : $themes | $pl | $ch\n  Moment émotionnel : ${s.emotionBeat} · Fil : ${s.lesson}';
  }

  @override
  List<Object?> get props => [
        storyWorld,
        recentSnapshots,
        repetitionAvoidance,
        nextNarrativeIntent,
      ];
}
