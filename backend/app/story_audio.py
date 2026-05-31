from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class StoryAudio:
    audio_status: str = "unavailable"
    audio_url: str | None = None
    audio_voice: str | None = None
    audio_duration: int | None = None


class TtsProvider(Protocol):
    def generate(self, *, story_id: str, text: str, voice: str | None = None) -> StoryAudio: ...


class AudioGenerationService(Protocol):
    def enqueue(self, story_id: str) -> None: ...

    def regenerate(self, story_id: str) -> None: ...
