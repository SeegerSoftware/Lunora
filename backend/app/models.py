from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


class UserPayload(BaseModel):
    model_config = ConfigDict(extra="allow")

    id: str = Field(min_length=1)
    email: str | None = None


class ChildPayload(BaseModel):
    model_config = ConfigDict(extra="allow")

    id: str = Field(min_length=1)
    userId: str = Field(min_length=1)
    firstName: str = ""
    preferredTone: str = "reassuring"
    storyLengthMinutes: int = Field(default=10, ge=1, le=30)
    seriesDurationDays: int = Field(default=7, ge=0, le=31)
    language: str = "fr"
    preferredThemes: list[str] = Field(default_factory=list)
    avoidThemes: list[str] = Field(default_factory=list)
    personalityTraits: list[str] = Field(default_factory=list)
    extraStoryHints: str = ""


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

    planId: str = "plan_elunai"
    email: str | None = None
