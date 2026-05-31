from typing import Protocol


class StoryIllustrationService(Protocol):
    def enqueue_generation(self, story_id: str, cover_prompt: str) -> None: ...

    def regenerate(self, story_id: str, cover_prompt: str) -> None: ...

    def cached_url(self, story_id: str) -> str | None: ...


def build_cover_prompt(result: dict, child: dict) -> str:
    return (
        "Portrait storybook cover, premium children's book illustration, "
        f"calm bedtime mood, title concept: {result.get('title', '')}, "
        f"theme: {result.get('theme', '')}, universe: "
        f"{child.get('universeType') or child.get('preferredUniverse') or 'dreamlike night'}, "
        "no text, no logo, portrait ratio"
    )
