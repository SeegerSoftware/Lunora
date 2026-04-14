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

/// Garde-fous : mots interdits, longueur, thèmes à éviter (parent), indices de fin apaisante.
class LocalContentSafetyPolicy implements ContentSafetyPolicy {
  const LocalContentSafetyPolicy();

  static const _blockedTokens = <String>{
    'sang',
    'sanglant',
    'mort',
    'mourir',
    'tuer',
    'arme',
    'pistolet',
    'horreur',
    'sexe',
    'sexy',
    'porn',
    'suicide',
  };

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
  };

  @override
  bool assertChildFriendly({
    required ChildProfile profile,
    required StoryGenerationDraft draft,
  }) {
    final haystack = '${draft.title} ${draft.summary} ${draft.content}'.toLowerCase();
    for (final token in _blockedTokens) {
      if (haystack.contains(token)) return false;
    }
    final body = draft.content.trim();
    if (body.length < 400) return false;

    for (final avoid in profile.avoidThemes) {
      final a = avoid.trim().toLowerCase();
      if (a.length < 3) continue;
      final re = RegExp(r'\b' + RegExp.escape(a) + r'\b');
      if (re.hasMatch(haystack)) return false;
    }

    final tail = body.length > 320 ? body.substring(body.length - 320).toLowerCase() : haystack;
    var soothing = 0;
    for (final h in _soothingHints) {
      if (tail.contains(h)) soothing++;
    }
    if (soothing < 1) return false;

    return true;
  }
}
