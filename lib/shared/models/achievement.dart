import 'package:equatable/equatable.dart';

import 'story.dart';

class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;

  @override
  List<Object?> get props => [id, label, description];
}

abstract final class AchievementCalculator {
  static const _storyMilestones = <int, Achievement>{
    1: Achievement(
      id: 'first_story',
      label: 'Première histoire',
      description: 'Le premier rituel du soir est dans la bibliothèque.',
    ),
    7: Achievement(
      id: 'stories_7',
      label: '7 histoires lues',
      description: 'Une semaine de souvenirs du soir.',
    ),
    30: Achievement(
      id: 'stories_30',
      label: '30 histoires lues',
      description: 'Un mois de moments partagés.',
    ),
    100: Achievement(
      id: 'stories_100',
      label: '100 histoires lues',
      description: 'Une bibliothèque familiale qui grandit.',
    ),
    365: Achievement(
      id: 'stories_365',
      label: '365 histoires lues',
      description: 'Une année de rituels précieux.',
    ),
  };

  static List<Achievement> earned(List<Story> stories) {
    final achievements = <Achievement>[];
    for (final entry in _storyMilestones.entries) {
      if (stories.length >= entry.key) achievements.add(entry.value);
    }
    if (stories.any(
      (story) =>
          story.isSerialized && story.chapterNumber >= story.totalChapters,
    )) {
      achievements.add(
        const Achievement(
          id: 'first_series_completed',
          label: 'Première série terminée',
          description: 'Une aventure complète à relire ensemble.',
        ),
      );
    }
    return achievements;
  }
}
