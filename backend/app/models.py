from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


class UserPayload(BaseModel):
    model_config = ConfigDict(extra="allow")

    id: str = Field(min_length=1, max_length=128)
    email: str | None = Field(default=None, max_length=320)


class ChildPayload(BaseModel):
    model_config = ConfigDict(extra="allow")

    id: str = Field(min_length=1, max_length=128)
    userId: str = Field(min_length=1, max_length=128)
    firstName: str = Field(default="", max_length=80)
    preferredTone: str = Field(default="reassuring", max_length=80)
    storyLengthMinutes: int = Field(default=10, ge=1, le=30)
    seriesDurationDays: int = Field(default=7, ge=0, le=31)
    language: str = Field(default="fr", max_length=16)
    preferredThemes: list[str] = Field(default_factory=list, max_length=20)
    avoidThemes: list[str] = Field(default_factory=list, max_length=20)
    personalityTraits: list[str] = Field(default_factory=list, max_length=20)
    extraStoryHints: str = Field(default="", max_length=1000)


class StoryGenerationPayload(BaseModel):
    model_config = ConfigDict(extra="allow")

    kind: Literal["story", "series_bible"] = "story"
    user: UserPayload
    child: ChildPayload
    dateKey: str | None = None
    chapterIndex: int = Field(default=1, ge=1, le=31)
    totalChapters: int = Field(default=1, ge=1, le=31)
    seriesId: str | None = None
    continuityContext: str | None = None
    seriesFilRougeBlock: str | None = None
    ageYears: int | None = Field(default=None, ge=0, le=18)
    memoryPromptBlock: str | None = None
    memoryContext: dict[str, Any] | None = None
    seriesBible: dict[str, Any] | None = None
    seriesState: dict[str, Any] | None = None
    currentChapterPlan: dict[str, Any] | None = None


class StripeCheckoutPayload(BaseModel):
    model_config = ConfigDict(extra="forbid")

    planId: str = Field(default="plan_elunai", max_length=80)
    email: str | None = Field(default=None, max_length=320)
