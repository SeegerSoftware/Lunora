import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../domain/story_memory_context.dart';
import '../domain/story_memory_snapshot.dart';
import '../domain/story_world.dart';

/// Assemble le contexte mémoire injecté dans le prompt (sans I/O).
abstract final class StoryMemoryBuilder {
  static StoryMemoryContext build({
    required StoryWorld storyWorld,
    required List<StoryMemorySnapshot> recentSnapshots,
    required ChildProfile child,
    required int chapterIndex,
    required int totalChapters,
  }) {
    final repetition = _repetitionAvoidance(storyWorld, recentSnapshots);
    final intent = _nextNarrativeIntent(
      storyWorld,
      child,
      chapterIndex: chapterIndex,
      totalChapters: totalChapters,
    );
    return StoryMemoryContext(
      storyWorld: storyWorld,
      recentSnapshots: List<StoryMemorySnapshot>.from(recentSnapshots),
      repetitionAvoidance: repetition,
      nextNarrativeIntent: intent,
    );
  }

  static String _repetitionAvoidance(
    StoryWorld world,
    List<StoryMemorySnapshot> snaps,
  ) {
    final parts = <String>{};
    for (final e in world.recentlyUsedElements) {
      final t = e.trim();
      if (t.isNotEmpty) parts.add(t);
    }
    for (final s in snaps) {
      parts.addAll(s.usedThemes);
      parts.addAll(s.usedPlaces);
      parts.addAll(s.usedCharacters);
    }
    if (parts.isEmpty) {
      return '(Encore peu d’historique : reste cohérent avec le monde, en évitant les clichés évidents.)';
    }
    final list = parts.toList()..sort();
    if (list.length > 24) {
      return list.sublist(list.length - 24).join(', ');
    }
    return list.join(', ');
  }

  static String _nextNarrativeIntent(
    StoryWorld world,
    ChildProfile child, {
    required int chapterIndex,
    required int totalChapters,
  }) {
    final hero =
        child.firstName.trim().isEmpty ? 'l’enfant' : child.firstName.trim();
    final serialized = child.storyFormat == StoryFormat.serializedChapters;
    if (serialized) {
      final last = chapterIndex >= totalChapters && totalChapters > 0;
      if (last) {
        return 'Conclure l’arc avec douceur pour $hero : refermer les fils du monde « ${world.worldName} » tout en laissant une sensation de sécurité durable.';
      }
      return 'Faire progresser l’arc (chapitre $chapterIndex / $totalChapters) : ancrer $hero, ${world.mainCompanion} et ${world.magicItem}, en variant les lieux parmi : ${world.recurringPlaces.join(", ")}.';
    }
    return 'Raconter une histoire du soir complète qui nourrit le lien entre $hero et le monde « ${world.worldName} », sans répéter mot pour mot les derniers épisodes listés en mémoire récente.';
  }
}
