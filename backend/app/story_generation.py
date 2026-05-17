import json
import os
from typing import Any

from fastapi import HTTPException


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
    content = (
        f"Ce soir, {name} découvre une petite lumière posée près de son oreiller.\n\n"
        "Elle ne fait aucun bruit, elle respire doucement comme une veilleuse. "
        "Avec elle, chaque pensée devient plus légère et chaque objet de la chambre "
        "retrouve sa place tranquille.\n\n"
        f"Au chapitre {chapter} sur {total}, l'aventure avance sans peur. "
        f"{name} comprend qu'une grande histoire peut commencer par un tout petit pas."
    )
    return {
        "title": f"La lumière douce de {name}",
        "content": content,
        "summary": "Une histoire calme pour terminer la journée.",
        "theme": "Rituel du soir",
        "tone": child.get("preferredTone", "reassuring"),
        "estimatedReadingMinutes": child.get("storyLengthMinutes", 10),
        "chapterNumber": chapter,
        "totalChapters": total,
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


def _mock_bible(payload: dict[str, Any]) -> dict[str, Any]:
    child = payload.get("child")
    if not isinstance(child, dict):
        raise HTTPException(status_code=422, detail="child payload is required")
    total = int(payload.get("totalChapters") or child.get("seriesDurationDays") or 7)
    return {
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


def generate_story(payload: dict[str, Any]) -> dict[str, Any]:
    if os.getenv("OPENAI_MOCK", "").lower() == "true":
        return _mock_story(payload)
    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    if not api_key:
        raise HTTPException(status_code=503, detail="OPENAI_API_KEY is not configured")
    from openai import OpenAI

    client = OpenAI(api_key=api_key)
    response = client.chat.completions.create(
        model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": _system_prompt()},
            {"role": "user", "content": _story_prompt(payload)},
        ],
        temperature=0.55,
        max_tokens=int(os.getenv("OPENAI_MAX_TOKENS", "4500")),
    )
    return _extract_json(response.choices[0].message.content or "")


def generate_series_bible(payload: dict[str, Any]) -> dict[str, Any]:
    if os.getenv("OPENAI_MOCK", "").lower() == "true":
        return _mock_bible(payload)
    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    if not api_key:
        raise HTTPException(status_code=503, detail="OPENAI_API_KEY is not configured")
    from openai import OpenAI

    client = OpenAI(api_key=api_key)
    response = client.chat.completions.create(
        model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": _system_prompt()},
            {"role": "user", "content": _series_bible_prompt(payload)},
        ],
        temperature=0.45,
        max_tokens=int(os.getenv("OPENAI_MAX_TOKENS", "4500")),
    )
    return _extract_json(response.choices[0].message.content or "")
