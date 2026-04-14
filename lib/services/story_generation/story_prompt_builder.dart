import '../../core/utils/age_calculator.dart';
import '../../shared/models/enums/story_format.dart';
import '../../shared/models/enums/story_tone.dart';
import '../../shared/models/enums/universe_type.dart';
import 'models/story_generation_request.dart';

/// Prompt structuré pour le LLM — modèle éditorial + contraintes + JSON.
class StoryPromptBuilder {
  const StoryPromptBuilder();

  String buildSystemPreamble() {
    return '''
Tu es un auteur spécialisé dans les histoires pour enfants racontées au moment du coucher.

Tu écris des histoires que les parents lisent à voix haute à leur enfant le soir.

Ton objectif est de produire une histoire :
- douce
- immersive
- facile à lire à voix haute
- adaptée à l’âge de l’enfant
- rassurante et apaisante
- avec une fin positive

Réponds uniquement par un objet JSON valide, sans texte hors JSON (voir schéma dans le message utilisateur).
'''
        .trim();
  }

  String buildUserPrompt(StoryGenerationRequest request) {
    final child = request.child;
    final age = AgeCalculator.ageInYears(
      birthMonth: child.birthMonth,
      birthYear: child.birthYear,
    );

    final formatWire = child.storyFormat == StoryFormat.serializedChapters
        ? 'serialized'
        : 'daily';

    final isSerialized = child.storyFormat == StoryFormat.serializedChapters;
    final isLastChapter =
        request.chapterIndex >= request.totalChapters && request.totalChapters > 0;
    final wordRange = _wordCountGuidance(child.storyLengthMinutes);
    final displayName =
        child.firstName.trim().isEmpty ? 'l’enfant' : child.firstName.trim();

    final buffer = StringBuffer()
      ..writeln('==================================================')
      ..writeln('CONTEXTE ENFANT')
      ..writeln('==================================================')
      ..writeln()
      ..writeln('Prénom : ${child.firstName}')
      ..writeln('Âge : $age ans')
      ..writeln()
      ..writeln(
        'Le personnage principal est l’enfant lui-même ($displayName). '
        'Place $displayName au centre de l’action, avec bienveillance.',
      )
      ..writeln()
      ..writeln('Traits de personnalité :')
      ..writeln(_join(child.personalityTraits))
      ..writeln()
      ..writeln('Thèmes préférés :')
      ..writeln(_join(child.preferredThemes))
      ..writeln()
      ..writeln('Thèmes à éviter :')
      ..writeln(_join(child.avoidThemes))
      ..writeln()
      ..writeln('Peurs à travailler :')
      ..writeln(_join(child.fearsToAddress))
      ..writeln()
      ..writeln('Valeurs à transmettre :')
      ..writeln(_join(child.valuesToTeach))
      ..writeln()
      ..writeln('Type d’univers :')
      ..writeln(child.universeType.displayLabel)
      ..writeln()
      ..writeln('Ton souhaité :')
      ..writeln(child.preferredTone.displayLabel)
      ..writeln();

    final memory = request.memoryContext;
    if (memory != null) {
      buffer
        ..writeln('==================================================')
        ..writeln('MÉMOIRE NARRATIVE (Lunora)')
        ..writeln('==================================================')
        ..writeln()
        ..writeln(memory.buildPromptBlock())
        ..writeln();
    }

    buffer
      ..writeln('==================================================')
      ..writeln('CONTEXTE HISTOIRE')
      ..writeln('==================================================')
      ..writeln()
      ..writeln('Durée cible :')
      ..writeln('${child.storyLengthMinutes} minutes')
      ..writeln()
      ..writeln('Longueur cible : environ $wordRange mots')
      ..writeln()
      ..writeln('Débit de lecture (important pour la longueur du texte) :')
      ..writeln(
        'Le parent lit à voix haute à environ 200 mots par minute. '
        'Ajuste la longueur du champ « content » pour tenir la durée cible '
        '(${child.storyLengthMinutes} min), sans précipitation ni surcharge.',
      )
      ..writeln()
      ..writeln('Format :')
      ..writeln('$formatWire  (daily = histoire complète ce soir ; serialized = épisode d’une série)')
      ..writeln()
      ..writeln('Chapitre :')
      ..writeln('${request.chapterIndex} / ${request.totalChapters}')
      ..writeln()
      ..writeln('Référence calendrier (ne pas citer mot pour mot si artificiel) : ${request.dateKey}')
      ..writeln();

    final fil = request.memoryContext == null
        ? request.seriesFilRougeBlock?.trim()
        : null;
    if (fil != null && fil.isNotEmpty) {
      buffer
        ..writeln('==================================================')
        ..writeln('FIL ROUGE DE LA SÉRIE')
        ..writeln('==================================================')
        ..writeln()
        ..writeln(fil)
        ..writeln();
    }

    final continuity = request.continuityContext?.trim();
    if (continuity != null && continuity.isNotEmpty) {
      buffer
        ..writeln('==================================================')
        ..writeln('CONTINUITÉ SÉRIE (chapitres précédents)')
        ..writeln('==================================================')
        ..writeln()
        ..writeln(continuity)
        ..writeln();
    }

    buffer
      ..writeln('==================================================')
      ..writeln('INSTRUCTIONS NARRATIVES')
      ..writeln('==================================================')
      ..writeln()
      ..writeln('VARIATION (anti répétition) :')
      ..writeln(
        'Ne réutilise pas les mêmes structures narratives, débuts ou expressions que dans les histoires précédentes.',
      )
      ..writeln(
        'Varie les situations, les personnages secondaires et les environnements.',
      )
      ..writeln()
      ..writeln('ANTI-RÉPÉTITION GLOBALE :')
      ..writeln(
        'Varie le style, le rythme et les situations pour éviter toute répétition entre les histoires.',
      )
      ..writeln()
      ..writeln('EXPÉRIENCE ÉMOTIONNELLE :')
      ..writeln(
        'Chaque histoire doit contenir un moment émotionnel doux (courage, fierté, amitié ou réconfort).',
      )
      ..writeln('Créer une connexion émotionnelle avec l’enfant.')
      ..writeln()
      ..writeln('RITUEL DU COUCHER :')
      ..writeln(
        'Le rythme de l’histoire doit ralentir progressivement.',
      )
      ..writeln(
        'La fin doit être apaisante et favoriser l’endormissement.',
      )
      ..writeln()
      ..writeln('VARIATION DU RYTHME :')
      ..writeln(
        'Alterne entre moments calmes et moments légèrement dynamiques sans jamais devenir stressant.',
      )
      ..writeln()
      ..writeln('IMMERSION SENSORIELLE :')
      ..writeln(
        'Ajoute de petits détails sensoriels (sons, lumière douce, sensations) pour rendre l’histoire vivante sans l’alourdir.',
      )
      ..writeln()
      ..writeln('IMPORTANT :')
      ..writeln()
      ..writeln('1. L’histoire doit être agréable à lire à voix haute à ~200 mots/minute :')
      ..writeln('- phrases fluides')
      ..writeln('- pas trop longues')
      ..writeln('- rythme naturel')
      ..writeln()
      ..writeln('2. Le style doit être naturel et non robotique :')
      ..writeln('- évite les répétitions')
      ..writeln('- évite les structures mécaniques')
      ..writeln('- évite les phrases génériques')
      ..writeln()
      ..writeln('3. Structure attendue :')
      ..writeln()
      ..writeln('Si format = daily :')
      ..writeln('- introduction douce')
      ..writeln('- petite aventure adaptée à l’enfant')
      ..writeln('- moment émotionnel léger')
      ..writeln('- résolution simple')
      ..writeln('- fin calme et rassurante')
      ..writeln()
      ..writeln('Si format = serialized :')
      ..writeln('- continuité avec les chapitres précédents (ou installation si premier chapitre)')
      ..writeln('- progression narrative douce')
      ..writeln('- pas de conclusion finale sauf dernier chapitre');

    if (isSerialized) {
      buffer
        ..writeln()
        ..writeln('Règles de fin pour le format serialized :')
        ..writeln(
          'Si ce n’est pas le dernier chapitre (chapitre ${request.chapterIndex} sur ${request.totalChapters}) :',
        )
        ..writeln('- ne termine pas complètement l’histoire')
        ..writeln('- laisse une légère continuité')
        ..writeln()
        ..writeln(
          isLastChapter
              ? 'Ce chapitre est le DERNIER de la série : fournis une conclusion complète et rassurante, qui referme l’arc avec douceur.'
              : 'Ce chapitre n’est pas le dernier : ne fournis pas de conclusion définitive de toute la série.',
        );
    }

    buffer
      ..writeln()
      ..writeln('4. Ton :')
      ..writeln('- rassurant')
      ..writeln('- bienveillant')
      ..writeln('- jamais anxiogène')
      ..writeln('- jamais violent')
      ..writeln()
      ..writeln('5. Adaptation à l’âge :')
      ..writeln('- vocabulaire simple')
      ..writeln('- concepts compréhensibles')
      ..writeln('- phrases courtes à moyennes')
      ..writeln()
      ..writeln('6. Gestion des peurs :')
      ..writeln('- si une peur est mentionnée, elle doit être abordée avec douceur')
      ..writeln('- transformer la peur en quelque chose de rassurant')
      ..writeln()
      ..writeln('7. Valeurs :')
      ..writeln('- intégrer les valeurs de manière naturelle')
      ..writeln('- pas de morale forcée')
      ..writeln()
      ..writeln('8. Fin :')
      ..writeln('- toujours positive')
      ..writeln('- apaisante')
      ..writeln('- adaptée au coucher')
      ..writeln()
      ..writeln('==================================================')
      ..writeln('CONTRAINTES STRICTES')
      ..writeln('==================================================')
      ..writeln()
      ..writeln('INTERDIT :')
      ..writeln('- violence forte')
      ..writeln('- horreur')
      ..writeln('- mort')
      ..writeln('- contenu anxiogène')
      ..writeln('- sexualisation')
      ..writeln('- vocabulaire inadapté')
      ..writeln()
      ..writeln(_jsonFormatBlock(request));

    return buffer.toString().trim();
  }

  /// Plage indicative alignée sur la durée (minutes).
  static String _wordCountGuidance(int minutes) {
    switch (minutes) {
      case 5:
        return '600 à 800';
      case 15:
        return '1500 à 1800';
      case 10:
      default:
        return '1000 à 1300';
    }
  }

  String _jsonFormatBlock(StoryGenerationRequest request) {
    return '''
==================================================
FORMAT DE SORTIE (OBLIGATOIRE)
==================================================

Réponds uniquement avec un JSON valide, avec exactement ces clés :

{
  "title": "...",
  "content": "...",
  "summary": "...",
  "estimatedReadingMinutes": number,
  "theme": "...",
  "tone": "...",
  "chapterNumber": number,
  "totalChapters": number
}

Règles pour "tone" : utiliser un des noms techniques exacts :
reassuring | gentleAdventure | poetic | playfulSoft

Règles pour "chapterNumber" et "totalChapters" :
- Mets impérativement chapterNumber = ${request.chapterIndex} et totalChapters = ${request.totalChapters}.

Ne mets aucun texte en dehors du JSON.
'''
        .trim();
  }

  static String _join(List<String> items) {
    if (items.isEmpty) return '(aucun)';
    return items.map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');
  }
}
