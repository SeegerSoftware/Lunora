from dataclasses import asdict, dataclass


@dataclass(frozen=True)
class StoryAgeProfile:
    key: str
    min_age: int
    max_age: int
    min_words: int
    target_words: int
    max_words: int
    vocabulary: str
    structure: str
    pace: str
    max_characters: int
    emotional_level: str
    objective: str

    def to_dict(self) -> dict[str, int | str]:
        return asdict(self)

    def prompt_block(self) -> str:
        return (
            f"Profil narratif par age : {self.key}\n"
            f"- Objectif : {self.objective}\n"
            f"- Longueur obligatoire : {self.min_words} a {self.max_words} mots "
            f"(cible {self.target_words})\n"
            f"- Vocabulaire : {self.vocabulary}\n"
            f"- Structure : {self.structure}\n"
            f"- Rythme : {self.pace}\n"
            f"- Personnages principaux et secondaires : maximum {self.max_characters}\n"
            f"- Niveau emotionnel : {self.emotional_level}"
        )


_PROFILES = (
    StoryAgeProfile(
        key="0-2",
        min_age=0,
        max_age=2,
        min_words=300,
        target_words=400,
        max_words=500,
        vocabulary="extremement simple, concret et rassurant",
        structure="decouverte lineaire sans intrigue complexe, avec repetitions positives",
        pace="tres lent, phrases tres courtes",
        max_characters=2,
        emotional_level="apaisement et securite",
        objective="apaisement, repetition rassurante et decouverte simple",
    ),
    StoryAgeProfile(
        key="3-4",
        min_age=3,
        max_age=4,
        min_words=600,
        target_words=700,
        max_words=800,
        vocabulary="simple et image",
        structure="une intrigue unique, un probleme leger et une resolution rapide",
        pace="calme et lisible",
        max_characters=3,
        emotional_level="emerveillement et securite",
        objective="emerveillement et securite",
    ),
    StoryAgeProfile(
        key="5-6",
        min_age=5,
        max_age=6,
        min_words=800,
        target_words=900,
        max_words=1000,
        vocabulary="accessible avec quelques images poetiques",
        structure="mini-mission et plusieurs scenes clairement reliees",
        pace="varie avec davantage de dialogues",
        max_characters=4,
        emotional_level="imagination et confiance",
        objective="imagination et exploration",
    ),
    StoryAgeProfile(
        key="7-8",
        min_age=7,
        max_age=8,
        min_words=1000,
        target_words=1100,
        max_words=1200,
        vocabulary="riche mais immediatement comprehensible",
        structure="intrigue plus riche, continuite visible et evolution emotionnelle marquee",
        pace="aventure calme avec respiration entre les scenes",
        max_characters=5,
        emotional_level="curiosite, courage calme et serenite",
        objective="aventure calme",
    ),
    StoryAgeProfile(
        key="9-12",
        min_age=9,
        max_age=12,
        min_words=1200,
        target_words=1500,
        max_words=1800,
        vocabulary="jeunesse riche, nuance et fluide",
        structure="arc construit, personnages secondaires developpes et suspense leger",
        pace="roman jeunesse avec continuite forte et retour au calme final",
        max_characters=7,
        emotional_level="progression emotionnelle nuancee",
        objective="veritable roman jeunesse",
    ),
)


def story_age_profile(age_years: int | None) -> StoryAgeProfile:
    age = 6 if age_years is None else max(0, min(int(age_years), 12))
    for profile in _PROFILES:
        if profile.min_age <= age <= profile.max_age:
            return profile
    return _PROFILES[-1]
