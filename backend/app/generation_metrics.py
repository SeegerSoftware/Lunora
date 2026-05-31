import logging
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class StoryGenerationMetrics:
    user_id: str
    child_id: str
    story_id: str
    model_used: str
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    estimated_cost: float
    generation_time_ms: int
    quality_score: int
    rewrite_attempts: int
    fallback_used: bool

    def to_firestore(self) -> dict[str, Any]:
        return {
            "userId": self.user_id,
            "childId": self.child_id,
            "storyId": self.story_id,
            "modelUsed": self.model_used,
            "promptTokens": self.prompt_tokens,
            "completionTokens": self.completion_tokens,
            "totalTokens": self.total_tokens,
            "estimatedCost": round(self.estimated_cost, 8),
            "generationTimeMs": self.generation_time_ms,
            "qualityScore": self.quality_score,
            "rewriteAttempts": self.rewrite_attempts,
            "fallbackUsed": self.fallback_used,
            "createdAt": datetime.now(timezone.utc),
        }


def estimate_cost(model: str, prompt_tokens: int, completion_tokens: int) -> float:
    # Conservative configurable baseline for the currently deployed small model.
    if "mini" in model:
        return (prompt_tokens * 0.00000015) + (completion_tokens * 0.0000006)
    return (prompt_tokens * 0.000005) + (completion_tokens * 0.000015)


def persist_generation_metrics(db, metrics: StoryGenerationMetrics) -> None:
    try:
        now = datetime.now(timezone.utc)
        day = now.strftime("%Y-%m-%d")
        doc = metrics.to_firestore()
        db.collection("story_generation_metrics").document(
            f"{day}_{uuid4().hex}"
        ).set(doc)
        aggregate = db.collection("story_generation_daily").document(day)
        try:
            from google.cloud.firestore_v1 import Increment

            aggregate.set(
                {
                    "dateKey": day,
                    "generationCount": Increment(1),
                    "totalTokens": Increment(metrics.total_tokens),
                    "estimatedCost": Increment(metrics.estimated_cost),
                    "fallbackCount": Increment(1 if metrics.fallback_used else 0),
                    "rewriteAttempts": Increment(metrics.rewrite_attempts),
                    "updatedAt": now,
                },
                merge=True,
            )
        except ImportError:
            logger.warning("Firestore Increment unavailable; daily metrics skipped")
    except Exception:
        logger.exception("Story generation metrics persistence failed")
