import '../../core/validation/story_profile_moderation.dart';
import '../../shared/models/child_profile.dart';

/// Règles éditoriales destinées à être renforcées côté serveur / modèle.
///
/// Le MVP applique une politique minimale côté client pour préparer
/// l’intégration d'un pipeline de modération (IA + humain).
abstract class ContentSafetyPolicy {
  bool assertChildFriendly({
    required ChildProfile profile,
    required StoryGenerationDraft draft,
  });
}

class StoryGenerationDraft {
  const StoryGenerationDraft({
    required this.title,
    required this.content,
    required this.summary,
  });

  final String title;
  final String content;
  final String summary;
}

/// Garde-fous : liste de modération, thèmes à éviter (parent), longueur, fin apaisante.
class LocalContentSafetyPolicy implements ContentSafetyPolicy {
  const LocalContentSafetyPolicy();

  /// Indices légers que la fin n’est pas anxiogène (derniers caractères).
  static const _soothingHints = <String>{
    'doux',
    'douce',
    'calme',
    'paix',
    'tranquille',
    'sommeil',
    'rêve',
    'câlin',
    'aimer',
    'ensemble',
    'demain',
    'repos',
    'sérénité',
    'dormir',
    'bien',
    'douceur',
  };

  @override
  bool assertChildFriendly({
    required ChildProfile profile,
    required StoryGenerationDraft draft,
  }) {
    final haystackRaw = '${draft.title} ${draft.summary} ${draft.content}';
    final haystack = StoryProfileModeration.foldAscii(haystackRaw);

    if (StoryProfileModeration.containsDisallowedContent(haystackRaw)) {
      return false;
    }

    if (StoryProfileModeration.validateChildProfile(profile) != null) {
      return false;
    }

    final body = draft.content.trim();
    if (body.length < 400) return false;

    for (final avoid in profile.avoidThemes) {
      final a = StoryProfileModeration.foldAscii(avoid.trim());
      if (a.length < 3) continue;
      final re = RegExp(r'\b' + RegExp.escape(a) + r'\b');
      if (re.hasMatch(haystack)) return false;
    }

    final tail = body.length > 320
        ? StoryProfileModeration.foldAscii(
            body.substring(body.length - 320),
          )
        : haystack;
    var soothing = 0;
    for (final h in _soothingHints) {
      if (tail.contains(h)) soothing++;
    }
    if (soothing < 1) return false;

    return true;
  }
}
