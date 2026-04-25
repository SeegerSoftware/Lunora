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
Tu es un auteur jeunesse francophone expert des histoires du soir pour enfants de 3 a 8 ans.

Ta mission est d'ecrire une histoire du soir personnalisee de qualite premium, en francais natif, naturel, fluide, chaleureux, rassurant et elegant, avec un rendu proche d'un vrai auteur jeunesse.

L'histoire doit etre immersive, emotionnellement juste, simple sans etre pauvre, imagee avec delicatesse, et pensee pour accompagner doucement l'enfant vers le sommeil.

Contraintes absolues :
- aucune violence
- aucune peur intense
- aucun conflit marque
- aucun danger reel
- aucun mechant agressif
- aucune surstimulation
- aucune morale lourde
- aucun humour moderne ou clin d'oeil qui casse l'univers
- aucune repetition artificielle
- aucune tournure scolaire, mecanique ou qui sonne "IA"

Objectifs litteraires :
- produire un recit vivant, naturel et fluide
- utiliser un vocabulaire simple mais riche
- creer des images douces et faciles a visualiser
- garder un ton tendre, calme et enveloppant
- donner l'impression qu'il s'agit d'un vrai auteur jeunesse francophone
- eviter les formulations generiques et plates

Regle de sortie :
- retourne uniquement un JSON valide
- aucun texte avant ou apres le JSON
- respecte strictement le schema demande dans le message utilisateur
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
    final minWords = _minWordsForMinutes(child.storyLengthMinutes, ageYears: age);
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
      ..writeln(
        _join(
          child.softenedFears.isEmpty ? child.fearsToAddress : child.softenedFears,
        ),
      )
      ..writeln()
      ..writeln('Valeurs à transmettre :')
      ..writeln(
        _join(
          child.valuesToTransmit.isEmpty
              ? child.valuesToTeach
              : child.valuesToTransmit,
        ),
      )
      ..writeln()
      ..writeln('Objectif émotionnel du soir :')
      ..writeln(child.tonightGoal)
      ..writeln()
      ..writeln('Type d’univers :')
      ..writeln(child.universeType.displayLabel)
      ..writeln()
      ..writeln('Ton souhaité :')
      ..writeln(child.preferredTone.displayLabel)
      ..writeln('Langue : ${child.language}')
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
      ..writeln('Longueur minimale stricte : $minWords mots')
      ..writeln()
      ..writeln('Lecture a voix haute (important pour la longueur du texte) :')
      ..writeln(
        'Le parent lit a voix haute avec une diction expressive et des pauses naturelles.'
        ' Repere de rythme : 0-3 ans 70-90 mots/min, 3-6 ans 90-110 mots/min, 6+ ans 110-120 mots/min.'
        ' Ajuste la longueur du champ "content" pour tenir la duree cible'
        ' (${child.storyLengthMinutes} min), sans rallonger artificiellement.',
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

    if (isSerialized && request.seriesBible != null) {
      final bible = request.seriesBible!;
      buffer
        ..writeln('==================================================')
        ..writeln('BIBLE DE SÉRIE (source de vérité)')
        ..writeln('==================================================')
        ..writeln()
        ..writeln('Titre : ${bible.seriesTitle}')
        ..writeln('Pitch : ${bible.pitch}')
        ..writeln('Univers : ${bible.universe}')
        ..writeln('Ton : ${bible.tone}')
        ..writeln('Objectif narratif : ${bible.storyArc}')
        ..writeln('Arc émotionnel : ${bible.emotionalArc}')
        ..writeln('Personnages principaux : ${_join(bible.mainCharacters)}')
        ..writeln('Personnages secondaires : ${_join(bible.secondaryCharacters)}')
        ..writeln('Lieux récurrents : ${_join(bible.recurringPlaces)}')
        ..writeln('Règles continuité : ${_join(bible.continuityRules)}')
        ..writeln('Anti-répétition : ${_join(bible.antiRepetitionRules)}')
        ..writeln('Fin prévue : ${bible.plannedEnding}')
        ..writeln();
    }

    if (isSerialized && request.seriesState != null) {
      final s = request.seriesState!;
      buffer
        ..writeln('==================================================')
        ..writeln('MÉMOIRE DE CONTINUITÉ (chapitres précédents)')
        ..writeln('==================================================')
        ..writeln()
        ..writeln('Résumé continuité : ${s.continuitySummary}')
        ..writeln('Dernier chapitre : ${s.lastChapterSummary}')
        ..writeln('Boucles ouvertes : ${_join(s.openLoops)}')
        ..writeln('Boucles résolues : ${_join(s.resolvedLoops)}')
        ..writeln('Objets importants : ${_join(s.importantObjects)}')
        ..writeln('Progression émotionnelle : ${_join(s.emotionalProgression)}')
        ..writeln('Mémoire anti-répétition : ${_join(s.antiRepetitionMemory)}')
        ..writeln('Objectif chapitre suivant : ${s.nextChapterGoal}')
        ..writeln();
    }

    if (isSerialized && request.currentChapterPlan != null) {
      final chapterPlan = request.currentChapterPlan!;
      buffer
        ..writeln('==================================================')
        ..writeln('CHAPITRE DU JOUR À PRODUIRE')
        ..writeln('==================================================')
        ..writeln()
        ..writeln('Chapitre: ${chapterPlan.chapterIndex}')
        ..writeln('Titre prévu: ${chapterPlan.title}')
        ..writeln('Objectif: ${chapterPlan.goal}')
        ..writeln('Étape émotionnelle: ${chapterPlan.emotionalStep}')
        ..writeln('Élément nouveau: ${chapterPlan.newElement}')
        ..writeln('Boucle à ouvrir/poursuivre: ${chapterPlan.openLoop}')
        ..writeln();
    }

    buffer
      ..writeln('==================================================')
      ..writeln('INSTRUCTIONS NARRATIVES')
      ..writeln('==================================================')
      ..writeln()
      ..writeln('STRUCTURE NARRATIVE OBLIGATOIRE :')
      ..writeln('1. introduction calme')
      ..writeln('2. élément perturbateur doux (micro-tension adaptée à l’âge)')
      ..writeln('3. exploration / interaction')
      ..writeln('4. résolution rassurante')
      ..writeln('5. retour au calme et endormissement')
      ..writeln()
      ..writeln('REGLES DE STYLE :')
      ..writeln(
        '- adapter longueur des phrases, vocabulaire et densite narrative a l’age de l’enfant',
      )
      ..writeln('- integrer le prenom naturellement, sans insistance')
      ..writeln('- utiliser reellement les themes donnes dans le recit')
      ..writeln('- privilegier des transitions fluides')
      ..writeln('- faire ralentir progressivement le rythme vers la fin')
      ..writeln('- finir avec une sensation de securite, de calme et de repos')
      ..writeln('- content doit contenir uniquement l’histoire (pas de meta-commentaire)')
      ..writeln('- inclure au moins un court dialogue naturel')
      ..writeln('- montrer une transformation émotionnelle entre début et fin')
      ..writeln()
      ..writeln('VARIATION (anti repetition) :')
      ..writeln(
        'Ne reutilise pas les memes structures narratives, debuts ou expressions que dans les histoires precedentes.',
      )
      ..writeln(
        'Varie les situations, les personnages secondaires et les environnements.',
      )
      ..writeln()
      ..writeln('ANTI-REPETITION GLOBALE :')
      ..writeln(
        'Varie le style, le rythme et les situations pour eviter toute repetition entre les histoires.',
      )
      ..writeln(
        'Evite de réutiliser les mêmes scènes d’ouverture, les mêmes métaphores et les mêmes formulations émotionnelles.',
      )
      ..writeln()
      ..writeln('EXPERIENCE EMOTIONNELLE :')
      ..writeln(
        'Chaque histoire doit contenir un moment emotionnel doux (courage, fierte, amitie ou reconfort).',
      )
      ..writeln('Creer une connexion emotionnelle avec l’enfant.')
      ..writeln()
      ..writeln('RITUEL DU COUCHER :')
      ..writeln(
        'Le rythme de l’histoire doit ralentir progressivement.',
      )
      ..writeln(
        'La fin doit etre apaisante et favoriser l’endormissement.',
      )
      ..writeln()
      ..writeln('VARIATION DU RYTHME :')
      ..writeln(
        'Alterne entre moments calmes et moments legerement dynamiques sans jamais devenir stressant.',
      )
      ..writeln()
      ..writeln('IMMERSION SENSORIELLE :')
      ..writeln(
        'Ajoute de petits détails sensoriels (sons, lumière douce, sensations) pour rendre l’histoire vivante sans l’alourdir.',
      )
      ..writeln()
      ..writeln('IMPORTANT :')
      ..writeln()
      ..writeln('1. L’histoire doit etre agreable a lire a voix haute :')
      ..writeln('- phrases fluides')
      ..writeln('- pas trop longues')
      ..writeln('- rythme naturel')
      ..writeln('- longueur suffisante (pas de version courte)')
      ..writeln()
      ..writeln('2. Le style doit etre naturel et non robotique :')
      ..writeln('- evite les repetitions')
      ..writeln('- evite les structures mecaniques')
      ..writeln('- evite les phrases generiques')
      ..writeln(
        '- viser un style de litterature jeunesse: images sensibles, rythme doux, mots simples',
      )
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
      ..writeln('- pas de conclusion finale sauf dernier chapitre')
      ..writeln('- ne réintroduis jamais un personnage connu comme nouveau')
      ..writeln('- évite toute ouverture répétée');

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
      ..writeln('- ajouter au moins un mini-apprentissage utile pour le quotidien')
      ..writeln()
      ..writeln('8. Fin :')
      ..writeln('- toujours positive')
      ..writeln('- apaisante')
      ..writeln('- adaptée au coucher')
      ..writeln()
      ..writeln('9. Longueur (obligatoire) :')
      ..writeln('- content doit contenir AU MOINS $minWords mots')
      ..writeln('- ne fournis jamais une version resumee')
      ..writeln(
        '- avant de repondre, verifie la longueur: si trop court, etends l\'histoire avec des scenes supplementaires douces',
      )
      ..writeln()
      ..writeln('10. Structure minimale recommandee pour atteindre la longueur :')
      ..writeln('- ouverture (mise en ambiance) : 15%')
      ..writeln('- aventure principale en 2 a 3 etapes : 55%')
      ..writeln('- resolution emotionnelle : 20%')
      ..writeln('- rituel de coucher / fermeture apaisante : 10%')
      ..writeln()
      ..writeln('11. Alignement au profil (obligatoire) :')
      ..writeln(
        '- utiliser explicitement au moins 2 éléments de "Thèmes préférés" quand disponibles',
      )
      ..writeln(
        '- intégrer au moins 1 valeur de "Valeurs à transmettre" de manière naturelle',
      )
      ..writeln(
        '- si des peurs sont renseignées, en adresser au moins 1 avec un dénouement rassurant',
      )
      ..writeln(
        '- tenir compte explicitement de l’objectif du soir dans l’arc émotionnel (ex: se rassurer, s’endormir calmement)',
      )
      ..writeln()
      ..writeln('12. Rythme narratif du coucher (obligatoire) :')
      ..writeln('- début calme')
      ..writeln('- léger pic émotionnel')
      ..writeln('- résolution douce')
      ..writeln('- descente progressive vers le sommeil')
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
      ..writeln('- histoire trop courte (moins de $minWords mots)')
      ..writeln('- histoire purement descriptive sans progression')
      ..writeln()
      ..writeln(_jsonFormatBlock(request));

    return buffer.toString().trim();
  }

  /// Plage indicative alignée sur la durée (minutes).
  static String _wordCountGuidance(int minutes) {
    switch (minutes) {
      case 5:
        return '260 à 520';
      case 15:
        return '620 à 1150';
      case 10:
      default:
        return '380 à 760';
    }
  }

  static int _minWordsForMinutes(int minutes, {required int ageYears}) {
    switch (minutes) {
      case 5:
        if (ageYears <= 4) return 220;
        if (ageYears <= 6) return 260;
        return 300;
      case 15:
        if (ageYears <= 4) return 520;
        if (ageYears <= 6) return 620;
        return 720;
      case 10:
      default:
        if (ageYears <= 4) return 320;
        if (ageYears <= 6) return 380;
        return 460;
    }
  }

  String _jsonFormatBlock(StoryGenerationRequest request) {
    final isSerialized =
        request.child.storyFormat == StoryFormat.serializedChapters;
    if (isSerialized) {
      return '''
==================================================
FORMAT DE SORTIE (OBLIGATOIRE)
==================================================

Réponds uniquement avec un JSON valide :

{
  "title": "...",
  "content": "...",
  "summary": "...",
  "estimatedReadingMinutes": number,
  "theme": "...",
  "tone": "...",
  "chapterNumber": number,
  "totalChapters": number,
  "format": "serialized",
  "continuityUpdate": {
    "chapterSummary": "...",
    "importantEvents": [],
    "charactersMet": [],
    "objectsIntroduced": [],
    "resolvedLoops": [],
    "openLoops": [],
    "emotionalStep": "...",
    "thingsToRemember": [],
    "thingsToAvoidRepeating": [],
    "nextChapterGoal": "..."
  }
}

Règles impératives :
- chapterNumber = ${request.chapterIndex}
- totalChapters = ${request.totalChapters}
- format = "serialized"
- continuityUpdate doit toujours être présent (même concis)

Ne mets aucun texte en dehors du JSON.
'''
          .trim();
    }
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

  String buildSeriesBiblePrompt(StoryGenerationRequest request) {
    final child = request.child;
    final age = AgeCalculator.ageInYears(
      birthMonth: child.birthMonth,
      birthYear: child.birthYear,
    );
    return '''
Crée une bible narrative de série en chapitres pour un enfant.

Contraintes fortes:
- histoire douce du coucher, ton calme
- pas de tension forte, pas de méchant effrayant
- progression émotionnelle claire
- chaque chapitre apporte un nouvel élément
- éviter les introductions répétées
- prévoir une vraie fin
- adapter strictement à l’âge: $age ans
- intégrer préférences du profil enfant

Profil enfant:
- prénom: ${child.firstName}
- langue: ${child.language}
- thèmes favoris: ${_join(child.preferredThemes)}
- thèmes à éviter: ${_join(child.avoidThemes)}
- personnalité: ${_join(child.personalityTraits)}
- peurs à accompagner: ${_join(child.softenedFears.isEmpty ? child.fearsToAddress : child.softenedFears)}
- valeurs à transmettre: ${_join(child.valuesToTransmit.isEmpty ? child.valuesToTeach : child.valuesToTransmit)}
- ton préféré: ${child.preferredTone.displayLabel}
- univers préféré: ${child.preferredUniverse.isEmpty ? child.universeType.displayLabel : child.preferredUniverse}
- niveau de magie: ${child.magicLevel}
- intensité aventure: ${child.adventureIntensity}
- durée série demandée: ${request.totalChapters} chapitres

Retourne uniquement ce JSON strict:
{
  "seriesTitle": "...",
  "pitch": "...",
  "universe": "...",
  "tone": "...",
  "mainCharacters": [],
  "secondaryCharacters": [],
  "recurringPlaces": [],
  "storyArc": "...",
  "emotionalArc": "...",
  "chapterPlan": [
    {
      "chapterIndex": 1,
      "title": "...",
      "goal": "...",
      "emotionalStep": "...",
      "newElement": "...",
      "openLoop": "..."
    }
  ],
  "continuityRules": [],
  "antiRepetitionRules": [],
  "plannedEnding": "..."
}
'''.trim();
  }

  static String _join(List<String> items) {
    if (items.isEmpty) return '(aucun)';
    return items.map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');
  }
}
