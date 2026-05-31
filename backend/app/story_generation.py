import json
import logging
import os
import time
from typing import Any

from fastapi import HTTPException

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
        "Tu es un auteur jeunesse francophone spécialisé dans les histoires du soir. "
        "Tu écris uniquement du contenu doux, non effrayant, adapté aux enfants, "
        "et tu réponds toujours en JSON strict."
    )


def _story_prompt(payload: dict[str, Any]) -> str:
    child = payload.get("child")
    if not isinstance(child, dict):
        raise HTTPException(status_code=422, detail="child payload is required")
    age = payload.get("ageYears") or "inconnu"
    target_words = _fallback_target_words(
        int(age) if isinstance(age, int) else 6,
        int(child.get("storyLengthMinutes") or 10),
    )
    themes = ", ".join(_read_list(child, "preferredThemes")) or "rituel du soir"
    traits = ", ".join(_read_list(child, "personalityTraits")) or "personnage doux"
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
Langue : {child.get("language", "fr")}
Thèmes souhaités : {themes}
Personnage / traits : {traits}
Style : {child.get("magicLevel", "fantastique doux")}
Ton : {child.get("preferredTone", "reassuring")}
Univers : {child.get("universeType", child.get("preferredUniverse", ""))}
À éviter : {avoid}
Notes parent : {child.get("extraStoryHints", "")}

Série : chapitre {chapter_index}/{total_chapters}
Bible de série éventuelle : {json.dumps(bible, ensure_ascii=False) if bible else "aucune"}
Plan du chapitre courant : {json.dumps(current_plan, ensure_ascii=False) if current_plan else "aucun"}
Contexte continuité : {payload.get("continuityContext") or ""}
Mémoire narrative : {memory}
Longueur cible : environ {target_words} mots, avec un minimum de {round(target_words * 0.75)} mots.

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
    requested_minutes = int(child.get("storyLengthMinutes") or 10)
    age_years = int(payload.get("ageYears") or 6)
    target_words = _fallback_target_words(age_years, requested_minutes)
    paragraphs = [
        f"Ce soir, {name} remarque une petite lumière posée près de son oreiller. "
        "Elle brille juste assez pour dessiner un chemin tranquille sur le tapis. "
        "La chambre reste silencieuse et familière. La lumière semble attendre sans "
        "se presser, comme une amie qui connaît déjà le chemin du repos.",
        f"{name} pose les pieds sur le tapis et avance doucement. À chaque pas, un "
        "petit reflet apparaît sur un objet connu : un livre, un coussin, une boîte "
        "à souvenirs. Rien ne bouge brusquement. Tout rappelle que les belles "
        "aventures peuvent commencer dans le calme.",
        "Au bout du chemin, une veilleuse ronde murmure une idée simple : pour "
        "continuer, il suffit de choisir un souvenir agréable de la journée. "
        f"{name} prend le temps de réfléchir, puis choisit un moment qui donne envie "
        "de sourire. La veilleuse devient un peu plus lumineuse.",
        "Un passage de lumière s'ouvre alors, comme une porte peinte avec des "
        "couleurs douces. De l'autre côté se trouve un jardin paisible. Les feuilles "
        "font un bruit léger, les fleurs se balancent lentement, et un banc attend "
        "près d'un petit bassin parfaitement calme.",
        f"{name} s'assoit sur le banc et observe les reflets. Chaque reflet raconte "
        "une petite chose rassurante : un rire partagé, un jeu terminé, une main "
        "tendue au bon moment. La veilleuse explique que ces souvenirs restent "
        "disponibles même quand la journée est finie.",
        "Plus loin, un pont très court traverse le bassin. Pour le franchir, il "
        "faut respirer lentement et compter quelques pas. Le pont ne demande ni "
        "vitesse ni courage extraordinaire. Il invite seulement à avancer avec "
        "patience, en remarquant combien le jardin est tranquille.",
        f"De l'autre côté, {name} trouve une petite boîte à musique. Elle joue une "
        "mélodie discrète, assez douce pour ne pas déranger la nuit. Dans la boîte, "
        "un papier porte quelques mots : les petites étapes comptent autant que les "
        "grandes, surtout lorsque vient le moment de se reposer.",
        "La veilleuse propose de rapporter ce message dans la chambre. Le jardin "
        "reste ouvert encore un instant, puis les couleurs se replient doucement "
        "comme les pages d'un livre. Le chemin de lumière revient sur le tapis, "
        "toujours paisible, toujours facile à suivre.",
        f"De retour près du lit, {name} replace la veilleuse à sa place. La chambre "
        "semble encore plus confortable qu'avant. Les objets familiers sont là, "
        "le coussin attend, et le souvenir choisi au début de l'aventure garde une "
        "petite chaleur agréable.",
        f"Avant de fermer les yeux, {name} pense au prochain chapitre de cette "
        "aventure calme. Il n'est pas nécessaire de tout découvrir ce soir. La "
        "veilleuse brillera encore demain. Pour maintenant, le chemin est rangé, "
        "le jardin se repose, et la nuit peut commencer doucement.",
    ]
    selected: list[str] = []
    while len(" ".join(selected).split()) < target_words:
        selected.append(paragraphs[len(selected) % len(paragraphs)])
    content = "\n\n".join(selected)
    return {
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


def _fallback_target_words(age_years: int, requested_minutes: int) -> int:
    base = 320 if age_years <= 2 else 600 if age_years <= 5 else 900 if age_years <= 8 else 1150
    factor = 0.7 if requested_minutes <= 5 else 1.3 if requested_minutes >= 15 else 1.0
    return round(base * factor)


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
    minimum_words = round(
        _fallback_target_words(
            int(payload.get("ageYears") or 6),
            int(child.get("storyLengthMinutes") or 10),
        )
        * 0.75
    )
    if len(content.split()) < minimum_words:
        raise ValueError(f"OpenAI story is too short ({len(content.split())} words)")
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
            return _extract_json(response.choices[0].message.content or "")
        except Exception as exc:  # pragma: no cover - exercised against provider in production
            last_error = exc
            logger.warning("OpenAI attempt %s/%s failed: %s", attempt, attempts, type(exc).__name__)
            if attempt < attempts:
                time.sleep(0.6 * attempt)
    raise RuntimeError("OpenAI generation failed") from last_error


def generate_story(payload: dict[str, Any]) -> dict[str, Any]:
    if os.getenv("OPENAI_MOCK", "").lower() == "true":
        return _mock_story(payload)
    attempts = max(1, int(os.getenv("OPENAI_VALIDATION_ATTEMPTS", "2")))
    for attempt in range(1, attempts + 1):
        try:
            return _normalize_story(
                _openai_json(_story_prompt(payload), temperature=0.55),
                payload,
            )
        except Exception:
            logger.exception("OpenAI story validation attempt %s/%s failed", attempt, attempts)
    logger.warning("Returning local story fallback")
    return _mock_story(payload)


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
