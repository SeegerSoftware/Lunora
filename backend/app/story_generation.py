import json
import logging
import os
import re
import time
import unicodedata
from typing import Any

from fastapi import HTTPException

from .story_age_profile import story_age_profile
from .story_illustrations import build_cover_prompt
from .story_quality import evaluate_story_quality

logger = logging.getLogger(__name__)


def _read_list(data: dict[str, Any], key: str) -> list[str]:
    raw = data.get(key)
    if not isinstance(raw, list):
        return []
    return [str(item).strip() for item in raw if str(item).strip()]


def _child_label(child: dict[str, Any]) -> str:
    first_name = str(child.get("firstName") or "").strip()
    return first_name or "l'enfant"


def _system_prompt() -> str:
    return (
        "Tu es un véritable auteur jeunesse francophone spécialisé dans les histoires "
        "du soir personnalisées. Tu écris une histoire complète, naturelle, imagée et "
        "rassurante, jamais une ébauche ni un texte générique. Tu respectes le prénom "
        "réel de l'enfant, les accents français et la continuité narrative. Tu évites "
        "toute peur intense, violence, menace, conflit fort ou suspense anxiogène. "
        "Tu réponds toujours en JSON strict conforme au format demandé."
    )


def _story_prompt(payload: dict[str, Any]) -> str:
    child = payload.get("child")
    if not isinstance(child, dict):
        raise HTTPException(status_code=422, detail="child payload is required")
    age = payload.get("ageYears") or "inconnu"
    profile = story_age_profile(payload.get("ageYears"))
    min_words, target_words, max_words = _story_word_bounds(payload.get("ageYears"))
    paragraph_guidance = "4 à 6" if profile.max_age <= 2 else "7 à 10" if profile.max_age <= 4 else "10 à 12"
    themes = ", ".join(_read_list(child, "preferredThemes")) or "rituel du soir"
    traits = ", ".join(_read_list(child, "personalityTraits")) or "personnage doux"
    familiar = ", ".join(_read_list(child, "familiarElements")) or "éléments familiers du coucher"
    values = ", ".join(_read_list(child, "valuesToTransmit")) or "confiance et apaisement"
    avoid = ", ".join(_read_list(child, "avoidThemes")) or "aucun thème précisé"
    chapter_index = int(payload.get("chapterIndex") or 1)
    total_chapters = int(payload.get("totalChapters") or 1)
    memory = str(payload.get("memoryPromptBlock") or "").strip()
    bible = payload.get("seriesBible")
    current_plan = payload.get("currentChapterPlan")

    return f"""
Génère une histoire du soir personnalisée.

Enfant : {_child_label(child)}
Âge : {age}
{profile.prompt_block()}
Langue : {child.get("language", "fr")}
Thèmes souhaités : {themes}
Personnage / traits : {traits}
Style : {child.get("magicLevel", "fantastique doux")}
Ton : {child.get("preferredTone", "reassuring")}
Univers : {child.get("universeType", child.get("preferredUniverse", ""))}
Éléments familiers à intégrer naturellement : {familiar}
Valeurs à transmettre : {values}
Objectif du soir : {child.get("tonightGoal", "s'endormir calmement")}
Intensité d'aventure : {child.get("adventureIntensity", "équilibrée")}
À éviter : {avoid}
Notes parent : {child.get("extraStoryHints", "")}

Série : chapitre {chapter_index}/{total_chapters}
Bible de série éventuelle : {json.dumps(bible, ensure_ascii=False) if bible else "aucune"}
Plan du chapitre courant : {json.dumps(current_plan, ensure_ascii=False) if current_plan else "aucun"}
Contexte continuité : {payload.get("continuityContext") or ""}
Mémoire narrative : {memory}
CONTRAINTE DE LONGUEUR OBLIGATOIRE :
- Le champ "content" seul doit contenir entre {min_words} et {max_words} mots.
- Vise environ {target_words} mots pour une lecture de 8 à 12 minutes.
- Écris {paragraph_guidance} paragraphes adaptés à l'âge, avec une vraie progression narrative.
- Avant de répondre, vérifie silencieusement la longueur de "content".
- Si le texte est trop court, enrichis les scènes, les descriptions et les dialogues.
- Ne résume jamais l'histoire et ne renvoie jamais une ébauche.

RÈGLES NARRATIVES OBLIGATOIRES :
- Le héros ou l'héroïne est l'enfant : utilise son prénom réel "{_child_label(child)}" plusieurs fois.
- N'utilise jamais une variable brute telle que "A", "childName", "prenom", "{{{{name}}}}" ou "{{{{child_name}}}}".
- Ne répète jamais un paragraphe, une scène ou une séquence pour atteindre la longueur.
- Donne à {_child_label(child)} une personnalité visible grâce à ses traits et à ses préférences.
- Construis un début, un développement et une fin.
- Ajoute une mini-mission simple et non stressante : trouver, aider, choisir, allumer ou réparer quelque chose.
- Ajoute au moins une interaction douce avec un personnage, un objet ou un élément magique.
- Fais évoluer l'émotion : curiosité, confiance, satisfaction, puis repos.
- Varie la longueur des phrases et les verbes. N'utilise pas "doucement", "tranquille" ou "paisible" dans chaque paragraphe.
- Utilise un français naturel, fluide et correctement accentué.
- Termine par un retour au calme dans la chambre, au lit ou dans un environnement rassurant.
- Ne termine pas par un cliffhanger stimulant. Le prochain chapitre peut seulement être évoqué de manière apaisante.

STRUCTURE RECOMMANDÉE :
1. Situation initiale familière.
2. Apparition d'un élément magique ou poétique.
3. Choix ou petite mission.
4. Exploration calme avec une interaction.
5. Découverte d'un message rassurant.
6. Retour dans la chambre ou au calme.
7. Phrase finale propice à l'endormissement.

Avant de finaliser, relis silencieusement "content" et corrige toute répétition,
variable non remplacée, formulation artificielle, incohérence ou scène trop excitante.

Réponds avec ce JSON :
{{
  "title": "...",
  "content": "histoire complète en paragraphes",
  "summary": "résumé court",
  "theme": "...",
  "tone": "{child.get("preferredTone", "reassuring")}",
  "estimatedReadingMinutes": {child.get("storyLengthMinutes", 10)},
  "chapterNumber": {chapter_index},
  "totalChapters": {total_chapters},
  "continuityUpdate": {{
    "chapterSummary": "...",
    "importantEvents": [],
    "charactersMet": [],
    "objectsIntroduced": [],
    "resolvedLoops": [],
    "openLoops": [],
    "emotionalStep": "...",
    "thingsToRemember": [],
    "thingsToAvoidRepeating": [],
    "relations": [{{"name": "...", "relationType": "...", "sinceChapter": {chapter_index}}}],
    "mysteries": [{{"question": "...", "openedAtChapter": {chapter_index}, "mustResolveBeforeChapter": {total_chapters}, "status": "open"}}],
    "narrativeObjects": [{{"name": "...", "importance": "supporting", "firstSeenChapter": {chapter_index}, "lastSeenChapter": {chapter_index}}}],
    "emotions": {{"confidence": 0, "courage": 0, "serenity": 0, "curiosity": 0}},
    "majorEvents": [{{"chapter": {chapter_index}, "event": "...", "impact": "..."}}],
    "doNotRepeat": [],
    "nextChapterGoal": "..."
  }}
}}
""".strip()


def _series_bible_prompt(payload: dict[str, Any]) -> str:
    child = payload.get("child")
    if not isinstance(child, dict):
        raise HTTPException(status_code=422, detail="child payload is required")
    total = int(payload.get("totalChapters") or child.get("seriesDurationDays") or 7)
    return f"""
Crée une bible de série douce pour {total} chapitres.

Enfant : {_child_label(child)}
Âge : {payload.get("ageYears") or "inconnu"}
Thèmes : {", ".join(_read_list(child, "preferredThemes"))}
Style : {child.get("magicLevel", "fantastique doux")}
Univers : {child.get("universeType", child.get("preferredUniverse", ""))}
Ton : {child.get("preferredTone", "reassuring")}
Notes parent : {child.get("extraStoryHints", "")}

Réponds avec ce JSON :
{{
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
    {{"chapterIndex": 1, "title": "...", "goal": "...", "emotionalStep": "...", "newElement": "...", "openLoop": "..."}}
  ],
  "continuityRules": [],
  "antiRepetitionRules": [],
  "plannedEnding": "..."
}}
""".strip()


def _mock_story(payload: dict[str, Any]) -> dict[str, Any]:
    child = payload.get("child")
    if not isinstance(child, dict):
        raise HTTPException(status_code=422, detail="child payload is required")
    name = _child_label(child)
    chapter = int(payload.get("chapterIndex") or 1)
    total = int(payload.get("totalChapters") or 1)
    profile = story_age_profile(payload.get("ageYears"))
    _, target_words, _ = _story_word_bounds(payload.get("ageYears"))
    paragraphs = [
        f"Ce soir, après avoir rangé ses affaires, {name} remarque près de son "
        "oreiller une petite lueur couleur de miel. Elle ne clignote pas comme une "
        "lampe ordinaire : elle respire lentement, au rythme de la chambre. Sur la "
        "table de nuit, les livres sont immobiles et le coussin attend déjà. "
        f"{name} s'approche, intrigué, sans avoir besoin de se presser.",
        "La lueur révèle alors une minuscule veilleuse ronde, coiffée d'un chapeau "
        "en forme d'étoile. « Bonsoir », murmure-t-elle d'une voix légère. Elle "
        "explique qu'une de ses étincelles s'est égarée avant l'heure du coucher. "
        "Sans cette étincelle, sa lumière reste un peu pâle. Elle ne demande pas "
        "une grande aventure, seulement un petit coup de main attentif.",
        f"{name} accepte cette mission simple : retrouver l'étincelle et la "
        "rapporter avant que la chambre ne s'endorme. La veilleuse propose trois "
        "endroits familiers où regarder : près des albums, sous le fauteuil et à "
        f"côté de la boîte à souvenirs. Après un instant de réflexion, {name} choisit "
        "de commencer par les livres, car leurs couvertures aiment garder les reflets.",
        "Entre deux albums, aucune étincelle n'apparaît, mais une image argentée "
        "brille sur une page. Elle représente un chemin bordé de feuilles souples. "
        "Lorsque la veilleuse approche son chapeau étoilé, le chemin se dessine sur "
        "le tapis comme un ruban de clair de lune. Il conduit jusqu'au fauteuil, "
        "sans quitter la chambre et sans faire le moindre bruit brusque.",
        f"Près du fauteuil, {name} découvre un petit bouton nacré. Il roule de "
        "quelques centimètres puis s'arrête contre le pied du meuble. « Ce n'est pas "
        "mon étincelle, mais il pourra nous guider », dit la veilleuse. Quand "
        f"{name} pose le bouton dans sa paume, celui-ci devient tiède et pointe vers "
        "la boîte à souvenirs avec un reflet discret.",
        "La boîte s'ouvre avec un léger soupir de papier. À l'intérieur se trouvent "
        "des images de la journée : un sourire partagé, un jeu terminé, une parole "
        "gentille, un moment où quelqu'un a pris le temps d'écouter. La veilleuse "
        "demande quel souvenir mérite de briller ce soir. Il n'y a pas de mauvaise "
        "réponse ; il suffit de choisir celui qui réchauffe le plus le cœur.",
        f"{name} observe chaque image, puis en choisit une. Aussitôt, le souvenir "
        "prend la forme d'une petite bulle lumineuse. Elle flotte au-dessus de la "
        "boîte et éclaire un fil presque invisible, posé sur le rebord. Le fil se "
        "déroule jusqu'à une poche secrète cachée dans la doublure. La veilleuse "
        "sourit : la recherche avance grâce à ce choix personnel.",
        "Dans la poche se trouve une enveloppe minuscule. Elle contient trois grains "
        "de lumière, mais un seul appartient à la veilleuse. Le premier frétille "
        "beaucoup trop vite, le deuxième s'éteint dès qu'on le regarde, et le "
        "troisième diffuse une chaleur régulière. « Lequel choisirais-tu ? » demande "
        "la veilleuse. La réponse semble bientôt évidente.",
        f"{name} désigne le troisième grain. À peine effleuré, il se pose sur le "
        "chapeau étoilé et retrouve sa place avec un petit son cristallin. La "
        "veilleuse ne devient pas éblouissante. Sa lumière est simplement plus "
        "ronde, plus chaleureuse, exactement comme il faut pour accompagner la fin "
        "de la journée sans réveiller les pensées déjà fatiguées.",
        "Pour remercier son partenaire de recherche, la veilleuse offre une dernière "
        "image : un jardin nocturne vu depuis une fenêtre imaginaire. Les herbes y "
        "ondulent lentement sous la lune et un banc de bois semble inviter à une "
        "pause. Aucun autre chemin ne s'ouvre, aucune nouvelle mission ne commence. "
        "Le jardin rappelle seulement que les petites réussites peuvent suffire.",
        "Avant de partir, la veilleuse invite à écouter quelques secondes. On entend "
        "à peine le froissement des feuilles imaginaires et le tic-tac régulier de "
        "la maison. Chaque son retrouve sa juste place. La veilleuse explique que "
        "le calme n'est pas un silence parfait : c'est un espace où les pensées "
        "peuvent ralentir et se poser l'une après l'autre.",
        f"{name} prend alors une respiration lente, puis une seconde. La petite "
        "lumière accompagne ce rythme sans donner d'ordre et sans se presser. Le "
        "jardin nocturne devient plus lointain, comme une illustration que l'on "
        "referme après l'avoir appréciée. Il restera disponible un autre soir, mais "
        "il n'a rien de plus à demander maintenant.",
        f"{name} remet le bouton nacré dans la boîte à souvenirs, referme le "
        "couvercle et replace les albums. Le ruban de clair de lune s'efface du "
        "tapis, laissant chaque chose à sa place. La veilleuse remercie encore "
        f"{name} : choisir, observer et aider avec patience lui a permis de réparer "
        "sa petite lumière avant la nuit.",
        f"Enfin, {name} retourne dans son lit et ajuste l'oreiller. La veilleuse "
        "reste sur la table de nuit, avec son éclat couleur de miel. La chambre "
        "retrouve son silence familier. Le souvenir choisi garde une chaleur douce, "
        "les paupières deviennent lourdes, et le sommeil peut arriver à son rythme, "
        "sans autre mission à accomplir ce soir.",
    ]
    selected: list[str] = []
    for paragraph in paragraphs:
        selected.append(paragraph)
        if len(" ".join(selected).split()) >= target_words:
            break
    content = "\n\n".join(selected)
    result = {
        "title": f"La lumière douce de {name}",
        "content": content,
        "summary": "Une histoire calme pour terminer la journée.",
        "theme": "Rituel du soir",
        "tone": child.get("preferredTone", "reassuring"),
        "estimatedReadingMinutes": child.get("storyLengthMinutes", 10),
        "chapterNumber": chapter,
        "totalChapters": total,
        "generationSource": "backend-fallback",
        "continuityUpdate": {
            "chapterSummary": "Une lumière douce accompagne le coucher.",
            "importantEvents": [],
            "charactersMet": [],
            "objectsIntroduced": ["lumière douce"],
            "resolvedLoops": [],
            "openLoops": [],
            "emotionalStep": "apaisement",
            "thingsToRemember": ["la lumière rassure"],
            "thingsToAvoidRepeating": [],
            "nextChapterGoal": "continuer calmement",
        },
    }
    quality = evaluate_story_quality(
        content,
        child_name=name,
        universe=str(child.get("universeType") or child.get("preferredUniverse") or ""),
        profile=profile,
        continuity_context=str(payload.get("continuityContext") or ""),
    )
    result.update(quality.to_dict())
    result.update(
        {
            "coverImageUrl": None,
            "coverImageStatus": "pending",
            "coverPrompt": build_cover_prompt(result, child),
            "audioStatus": "unavailable",
            "audioUrl": None,
            "audioVoice": None,
            "audioDuration": None,
            "modelUsed": "local-fallback",
            "promptTokens": 0,
            "completionTokens": 0,
            "totalTokens": 0,
            "estimatedCost": 0.0,
            "generationTimeMs": 0,
            "rewriteAttempts": 0,
            "fallbackUsed": True,
        }
    )
    return result


def _story_word_bounds(age_years: int | None = None) -> tuple[int, int, int]:
    if age_years is None:
        return (800, 1000, 1200)
    profile = story_age_profile(age_years)
    return (profile.min_words, profile.target_words, profile.max_words)


class StoryQualityError(ValueError):
    def __init__(self, issues: list[str]):
        self.issues = issues
        super().__init__("; ".join(issues))


def _canonical_text(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value.casefold())
    return " ".join(re.findall(r"[a-z0-9]+", normalized))


def _paragraphs(content: str) -> list[str]:
    return [paragraph.strip() for paragraph in re.split(r"\n\s*\n", content) if paragraph.strip()]


def _repeated_paragraphs(content: str) -> list[str]:
    seen: set[str] = set()
    repeated: list[str] = []
    for paragraph in _paragraphs(content):
        canonical = _canonical_text(paragraph)
        if canonical in seen:
            repeated.append(paragraph)
        seen.add(canonical)
    return repeated


def _repeated_sentences(content: str) -> list[str]:
    seen: set[str] = set()
    repeated: list[str] = []
    for sentence in re.split(r"(?<=[.!?])\s+", content):
        canonical = _canonical_text(sentence)
        if len(canonical.split()) < 8:
            continue
        if canonical in seen:
            repeated.append(sentence)
        seen.add(canonical)
    return repeated


def _contains_raw_variable(content: str) -> bool:
    return bool(
        re.search(
            r"(?i)(\{\{[^}]+\}\}|\{(?:child_?name|name|prenom|prénom)\}|"
            r"\bchild_?name\b|\bprenom\b|\bprénom\b)",
            content,
        )
        or re.search(r"\bA\b", content)
    )


def _contains_any(content: str, words: tuple[str, ...]) -> bool:
    canonical = _canonical_text(content)
    return any(_canonical_text(word) in canonical for word in words)


def _story_quality_issues(
    content: str,
    child_name: str,
    *,
    age_years: int | None = None,
    universe: str = "",
    continuity_context: str = "",
) -> list[str]:
    issues: list[str] = []
    profile = story_age_profile(8 if age_years is None else age_years)
    quality = evaluate_story_quality(
        content,
        child_name=child_name,
        universe=universe,
        profile=profile,
        continuity_context=continuity_context,
    )
    minimum_words, _, maximum_words = _story_word_bounds(age_years)
    word_count = len(content.split())
    if word_count < minimum_words:
        issues.append(f"histoire trop courte : {word_count} mots, minimum {minimum_words}")
    if word_count > maximum_words:
        issues.append(f"histoire trop longue : {word_count} mots, maximum {maximum_words}")
    minimum_paragraphs = 4 if profile.max_age <= 2 else 6 if profile.max_age <= 4 else 7
    if len(_paragraphs(content)) < minimum_paragraphs:
        issues.append(
            f"progression narrative insuffisante : moins de {minimum_paragraphs} paragraphes"
        )
    if _repeated_paragraphs(content):
        issues.append("un ou plusieurs paragraphes sont répétés")
    if _repeated_sentences(content):
        issues.append("une ou plusieurs phrases développées sont répétées")
    if _contains_raw_variable(content):
        issues.append("une variable brute non remplacée apparaît dans le texte")
    if child_name and _canonical_text(child_name) not in _canonical_text(content):
        issues.append(f"le prénom réel {child_name!r} n'apparaît pas dans l'histoire")
    if not _contains_any(content, ("mission", "trouver", "retrouver", "aider", "choisir", "allumer", "réparer", "rapporter")):
        issues.append("aucune mini-mission calme n'est identifiable")
    if not _contains_any(content, ("dit", "demande", "répond", "murmure", "propose", "explique", "sourit")):
        issues.append("aucune interaction douce n'est identifiable")
    ending = " ".join(_paragraphs(content)[-2:])
    if not _contains_any(ending, ("lit", "chambre", "oreiller", "sommeil", "dormir", "fermer les yeux", "nuit", "repos", "coucher")):
        issues.append("la fin ne revient pas clairement au calme ou au coucher")
    if "Ã" in content or "�" in content:
        issues.append("le texte contient des caractères français mal encodés")
    if quality.score < 85:
        issues.extend(warning for warning in quality.warnings if warning not in issues)
    return issues


def _corrective_story_prompt(prompt: str, issues: list[str]) -> str:
    details = "\n".join(f"- {issue}" for issue in issues)
    return f"""
{prompt}

CORRECTION OBLIGATOIRE APRÈS CONTRÔLE QUALITÉ :
La première version a été refusée pour les raisons suivantes :
{details}

Réécris entièrement l'histoire. Ne recycle aucun paragraphe de la version précédente.
Corrige tous les points listés avant de renvoyer le JSON final.
""".strip()


def _mock_bible(payload: dict[str, Any]) -> dict[str, Any]:
    child = payload.get("child")
    if not isinstance(child, dict):
        raise HTTPException(status_code=422, detail="child payload is required")
    total = int(payload.get("totalChapters") or child.get("seriesDurationDays") or 7)
    return {
        "generationSource": "backend-fallback",
        "seriesTitle": "Les petites lumières du soir",
        "pitch": "Une série calme où chaque soir apporte une découverte rassurante.",
        "universe": child.get("preferredUniverse", "Monde doux"),
        "tone": child.get("preferredTone", "reassuring"),
        "mainCharacters": [_child_label(child)],
        "secondaryCharacters": ["une veilleuse bienveillante"],
        "recurringPlaces": ["la chambre", "un chemin de lumière"],
        "storyArc": "Apprendre à accueillir le sommeil sereinement.",
        "emotionalArc": "Curiosité, confiance, apaisement.",
        "chapterPlan": [
            {
                "chapterIndex": i,
                "title": f"Petite lumière {i}",
                "goal": "avancer doucement",
                "emotionalStep": "confiance",
                "newElement": "un détail rassurant",
                "openLoop": "la prochaine lumière",
            }
            for i in range(1, total + 1)
        ],
        "continuityRules": ["Rester doux", "Éviter toute peur"],
        "antiRepetitionRules": ["Varier les lieux et objets"],
        "plannedEnding": "Un coucher paisible.",
    }


def _extract_json(raw: str) -> dict[str, Any]:
    text = raw.strip()
    if text.startswith("```"):
        text = text.strip("`")
        text = text.removeprefix("json").strip()
    start = text.find("{")
    end = text.rfind("}")
    if start < 0 or end <= start:
        raise HTTPException(status_code=502, detail="OpenAI response did not contain JSON")
    try:
        decoded = json.loads(text[start : end + 1])
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=502, detail="OpenAI response JSON is invalid") from exc
    if not isinstance(decoded, dict):
        raise HTTPException(status_code=502, detail="OpenAI response must be a JSON object")
    return decoded


def _completion_token_limit() -> dict[str, int]:
    return {"max_completion_tokens": int(os.getenv("OPENAI_MAX_TOKENS", "4500"))}


def _narrative_text(value: Any, fallback: str = "") -> str:
    if value is None:
        return fallback
    if isinstance(value, str):
        return value.strip() or fallback
    if isinstance(value, dict):
        for key in ("text", "title", "name", "label", "description", "summary", "goal", "value"):
            candidate = _narrative_text(value.get(key))
            if candidate:
                return candidate
        return ", ".join(filter(None, (_narrative_text(item) for item in value.values()))) or fallback
    if isinstance(value, list):
        return ", ".join(filter(None, (_narrative_text(item) for item in value))) or fallback
    return str(value).strip() or fallback


def _narrative_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [text for item in value if (text := _narrative_text(item))]


def _normalize_story(result: dict[str, Any], payload: dict[str, Any]) -> dict[str, Any]:
    child = payload.get("child") or {}
    content = _narrative_text(result.get("content"))
    profile = story_age_profile(payload.get("ageYears"))
    universe = str(child.get("universeType") or child.get("preferredUniverse") or "")
    continuity_context = str(payload.get("continuityContext") or "")
    quality = evaluate_story_quality(
        content,
        child_name=_child_label(child),
        universe=universe,
        profile=profile,
        continuity_context=continuity_context,
    )
    issues = _story_quality_issues(
        content,
        _child_label(child),
        age_years=payload.get("ageYears"),
        universe=universe,
        continuity_context=continuity_context,
    )
    if issues:
        raise StoryQualityError(issues)
    continuity = result.get("continuityUpdate")
    continuity = continuity if isinstance(continuity, dict) else {}
    for key in (
        "importantEvents",
        "charactersMet",
        "objectsIntroduced",
        "resolvedLoops",
        "openLoops",
        "thingsToRemember",
        "thingsToAvoidRepeating",
        "doNotRepeat",
    ):
        continuity[key] = _narrative_list(continuity.get(key))
    for key in ("chapterSummary", "emotionalStep", "nextChapterGoal"):
        continuity[key] = _narrative_text(continuity.get(key))
    result.update(
        {
            "title": _narrative_text(result.get("title"), "Histoire du soir"),
            "content": content,
            "summary": _narrative_text(result.get("summary"), "Une aventure douce."),
            "theme": _narrative_text(result.get("theme"), "Rituel du soir"),
            "tone": _narrative_text(result.get("tone"), str(child.get("preferredTone") or "reassuring")),
            "estimatedReadingMinutes": int(result.get("estimatedReadingMinutes") or child.get("storyLengthMinutes") or 10),
            "continuityUpdate": continuity,
            "generationSource": "backend-openai",
            "coverImageUrl": None,
            "coverImageStatus": "pending",
            "coverPrompt": build_cover_prompt(result, child),
            "audioStatus": "unavailable",
            "audioUrl": None,
            "audioVoice": None,
            "audioDuration": None,
            **quality.to_dict(),
        }
    )
    return result


def _openai_json(prompt: str, *, temperature: float) -> dict[str, Any]:
    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is not configured")
    from openai import OpenAI

    client = OpenAI(
        api_key=api_key,
        timeout=float(os.getenv("OPENAI_TIMEOUT_SECONDS", "45")),
        max_retries=0,
    )
    attempts = max(1, int(os.getenv("OPENAI_MAX_ATTEMPTS", "2")))
    last_error: Exception | None = None
    for attempt in range(1, attempts + 1):
        try:
            response = client.chat.completions.create(
                model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
                response_format={"type": "json_object"},
                messages=[
                    {"role": "system", "content": _system_prompt()},
                    {"role": "user", "content": prompt},
                ],
                temperature=temperature,
                **_completion_token_limit(),
            )
            result = _extract_json(response.choices[0].message.content or "")
            usage = response.usage
            prompt_tokens = int(getattr(usage, "prompt_tokens", 0) or 0)
            completion_tokens = int(getattr(usage, "completion_tokens", 0) or 0)
            result["_providerMetrics"] = {
                "modelUsed": str(
                    getattr(response, "model", "")
                    or os.getenv("OPENAI_MODEL", "gpt-4o-mini")
                ),
                "promptTokens": prompt_tokens,
                "completionTokens": completion_tokens,
                "totalTokens": int(
                    getattr(usage, "total_tokens", 0)
                    or prompt_tokens + completion_tokens
                ),
            }
            return result
        except Exception as exc:  # pragma: no cover - exercised against provider in production
            last_error = exc
            logger.warning("OpenAI attempt %s/%s failed: %s", attempt, attempts, type(exc).__name__)
            if attempt < attempts:
                time.sleep(0.6 * attempt)
    raise RuntimeError("OpenAI generation failed") from last_error


def generate_story(payload: dict[str, Any]) -> dict[str, Any]:
    if os.getenv("OPENAI_MOCK", "").lower() == "true":
        return _mock_story(payload)
    started = time.perf_counter()
    prompt = _story_prompt(payload)
    for attempt in range(1, 3):
        try:
            result = _normalize_story(
                _openai_json(prompt, temperature=0.55),
                payload,
            )
            provider_metrics = result.pop("_providerMetrics", {})
            result.update(provider_metrics)
            result["generationTimeMs"] = int((time.perf_counter() - started) * 1000)
            result["rewriteAttempts"] = attempt - 1
            result["fallbackUsed"] = False
            return result
        except StoryQualityError as exc:
            logger.warning("OpenAI story quality attempt %s/2 rejected: %s", attempt, exc)
            if attempt == 1:
                prompt = _corrective_story_prompt(prompt, exc.issues)
        except Exception:
            logger.exception("OpenAI story generation attempt %s/2 failed", attempt)
    logger.warning("Returning local story fallback")
    result = _mock_story(payload)
    result["generationTimeMs"] = int((time.perf_counter() - started) * 1000)
    result["rewriteAttempts"] = 2
    return result


def generate_series_bible(payload: dict[str, Any]) -> dict[str, Any]:
    if os.getenv("OPENAI_MOCK", "").lower() == "true":
        return _mock_bible(payload)
    try:
        result = _openai_json(_series_bible_prompt(payload), temperature=0.45)
        result["generationSource"] = "backend-openai"
        return result
    except Exception:
        logger.exception("OpenAI series bible generation failed; returning local fallback")
        return _mock_bible(payload)
