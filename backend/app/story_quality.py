import re
import unicodedata
from dataclasses import asdict, dataclass
from typing import Any

from .story_age_profile import StoryAgeProfile


@dataclass(frozen=True)
class StoryQualityResult:
    score: int
    details: dict[str, int]
    warnings: list[str]

    def to_dict(self) -> dict[str, Any]:
        return {
            "qualityScore": self.score,
            "qualityDetails": self.details,
            "qualityWarnings": self.warnings,
        }


def canonical_text(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value.casefold())
    return " ".join(re.findall(r"[a-z0-9]+", normalized))


def paragraphs(content: str) -> list[str]:
    return [item.strip() for item in re.split(r"\n\s*\n", content) if item.strip()]


def repeated_paragraphs(content: str) -> list[str]:
    seen: set[str] = set()
    repeated: list[str] = []
    for paragraph in paragraphs(content):
        canonical = canonical_text(paragraph)
        if canonical in seen:
            repeated.append(paragraph)
        seen.add(canonical)
    return repeated


def repeated_sentences(content: str) -> list[str]:
    seen: set[str] = set()
    repeated: list[str] = []
    for sentence in re.split(r"(?<=[.!?])\s+", content):
        canonical = canonical_text(sentence)
        if len(canonical.split()) < 8:
            continue
        if canonical in seen:
            repeated.append(sentence)
        seen.add(canonical)
    return repeated


def contains_raw_variable(content: str) -> bool:
    return bool(
        re.search(
            r"(?i)(\{\{[^}]+\}\}|\{(?:child_?name|name|prenom|pr.nom)\}|"
            r"\bchild_?name\b|\bprenom\b|\bpr.nom\b)",
            content,
        )
        or re.search(r"\bA\b", content)
    )


def contains_any(content: str, words: tuple[str, ...]) -> bool:
    canonical = canonical_text(content)
    return any(canonical_text(word) in canonical for word in words)


def evaluate_story_quality(
    content: str,
    *,
    child_name: str,
    universe: str,
    profile: StoryAgeProfile,
    continuity_context: str = "",
) -> StoryQualityResult:
    warnings: list[str] = []
    words = content.split()
    word_count = len(words)
    story_paragraphs = paragraphs(content)

    structure = 25
    if word_count < profile.min_words or word_count > profile.max_words:
        structure -= 12
        warnings.append(
            f"longueur hors profil {profile.key}: {word_count} mots, "
            f"attendu {profile.min_words}-{profile.max_words}"
        )
    if len(story_paragraphs) < 4:
        structure -= 8
        warnings.append("progression narrative insuffisante")
    if len(story_paragraphs) > 16:
        structure -= 3
        warnings.append("rythme fragmente par trop de paragraphes")

    personalization = 20
    canonical = canonical_text(content)
    if child_name and canonical_text(child_name) not in canonical:
        personalization -= 12
        warnings.append(f"le prenom reel {child_name!r} n'apparait pas")
    if universe and canonical_text(universe) not in canonical:
        personalization -= 3
        warnings.append("univers personnalise peu visible")

    literary = 20
    unique_ratio = len({canonical_text(word) for word in words}) / max(1, word_count)
    if unique_ratio < 0.22:
        literary -= 6
        warnings.append("vocabulaire trop repetitif")
    sentence_lengths = [
        len(sentence.split())
        for sentence in re.split(r"(?<=[.!?])\s+", content)
        if sentence.strip()
    ]
    if sentence_lengths and max(sentence_lengths) - min(sentence_lengths) < 4:
        literary -= 4
        warnings.append("phrases insuffisamment variees")

    continuity = 15
    if continuity_context and not any(
        token in canonical for token in canonical_text(continuity_context).split()[:24]
    ):
        continuity -= 5
        warnings.append("continuite avec les chapitres precedents peu visible")

    calming = 10
    ending = " ".join(story_paragraphs[-2:])
    if not contains_any(
        ending,
        ("lit", "chambre", "oreiller", "sommeil", "dormir", "nuit", "repos", "coucher"),
    ):
        calming -= 8
        warnings.append("la fin ne revient pas clairement au calme")
    if contains_any(content, ("violence", "terreur", "sang", "arme", "tuer", "hurlement")):
        calming -= 5
        warnings.append("stimulation ou vocabulaire anxiogene detecte")

    originality = 10
    if repeated_paragraphs(content):
        originality -= 7
        warnings.append("un ou plusieurs paragraphes sont repetes")
    if repeated_sentences(content):
        originality -= 4
        warnings.append("une ou plusieurs phrases developpees sont repetees")
    if contains_raw_variable(content):
        personalization -= 10
        warnings.append("une variable brute non remplacee apparait dans le texte")
    if "\u00c3" in content or "\ufffd" in content:
        literary -= 8
        warnings.append("le texte contient des caracteres mal encodes")

    details = {
        "structure": max(0, structure),
        "personalization": max(0, personalization),
        "literaryQuality": max(0, literary),
        "continuity": max(0, continuity),
        "calming": max(0, calming),
        "originality": max(0, originality),
    }
    return StoryQualityResult(
        score=max(0, min(100, sum(details.values()))),
        details=details,
        warnings=warnings,
    )
