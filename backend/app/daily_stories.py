import logging
import os
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4
from zoneinfo import ZoneInfo

from .auth import firestore_client
from .child_entitlements import max_children_for_user
from .story_generation import generate_series_bible, generate_story
from .generation_metrics import StoryGenerationMetrics, estimate_cost, persist_generation_metrics

logger = logging.getLogger(__name__)
LOCAL_TIMEZONE = ZoneInfo("Europe/Zurich")


def _as_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item).strip() for item in value if str(item).strip()]


def _age_years(child: dict[str, Any], now: datetime) -> int:
    year = int(child.get("birthYear") or now.year - 5)
    month = int(child.get("birthMonth") or 1)
    return max(0, now.year - year - (1 if now.month < month else 0))


def _state_doc_id(child_id: str, user_id: str) -> str:
    return f"{child_id}_{user_id}"


def _story_doc_id(child_id: str, user_id: str, date_key: str) -> str:
    return f"story_{user_id}_{child_id}_{date_key}"


def _new_series_state(
    *,
    child: dict[str, Any],
    user_id: str,
    date_key: str,
    bible: dict[str, Any],
    now: datetime,
) -> dict[str, Any]:
    child_id = str(child["id"])
    total = max(1, int(child.get("seriesDurationDays") or 7))
    plans = bible.get("chapterPlan") if isinstance(bible.get("chapterPlan"), list) else []
    anti_repetition = _as_list(bible.get("antiRepetitionRules"))
    return {
        "id": _state_doc_id(child_id, user_id),
        "seriesId": f"series_{child_id}_{date_key}_{uuid4().hex[:8]}",
        "childId": child_id,
        "userId": user_id,
        "status": "active",
        "seriesTitle": str(bible.get("seriesTitle") or "Serie du soir"),
        "seriesFormat": "serializedChapters",
        "currentChapterIndex": 0,
        "totalChapters": total,
        "seriesDurationDays": total,
        "universe": str(bible.get("universe") or ""),
        "tone": str(bible.get("tone") or child.get("preferredTone") or "reassuring"),
        "mainCharacters": _as_list(bible.get("mainCharacters")),
        "secondaryCharacters": _as_list(bible.get("secondaryCharacters")),
        "recurringPlaces": _as_list(bible.get("recurringPlaces")),
        "storyArc": str(bible.get("storyArc") or ""),
        "emotionalArc": str(bible.get("emotionalArc") or ""),
        "chapterPlan": plans,
        "continuitySummary": str(bible.get("pitch") or ""),
        "chapterSummaries": [],
        "openLoops": [],
        "resolvedLoops": [],
        "importantObjects": [],
        "emotionalProgression": [],
        "antiRepetitionMemory": anti_repetition,
        "antiRepetitionRules": anti_repetition,
        "chapterContinuityUpdates": [],
        "lastChapterSummary": "",
        "nextChapterGoal": str(plans[0].get("goal") or "") if plans else "",
        "createdAt": now,
        "updatedAt": now,
        "completedAt": None,
        "profileSnapshot": child,
    }


def _series_bible(state: dict[str, Any]) -> dict[str, Any]:
    return {
        "seriesTitle": state.get("seriesTitle"),
        "pitch": state.get("continuitySummary"),
        "universe": state.get("universe"),
        "tone": state.get("tone"),
        "mainCharacters": state.get("mainCharacters", []),
        "secondaryCharacters": state.get("secondaryCharacters", []),
        "recurringPlaces": state.get("recurringPlaces", []),
        "storyArc": state.get("storyArc"),
        "emotionalArc": state.get("emotionalArc"),
        "chapterPlan": state.get("chapterPlan", []),
        "antiRepetitionRules": state.get("antiRepetitionRules", []),
    }


def _advance_state(state: dict[str, Any], generated: dict[str, Any], chapter: int, now: datetime) -> dict[str, Any]:
    update = generated.get("continuityUpdate")
    update = update if isinstance(update, dict) else {}
    summary = str(update.get("chapterSummary") or generated.get("summary") or "")
    summaries = [*_as_list(state.get("chapterSummaries")), summary]
    updates = [*(state.get("chapterContinuityUpdates") or []), update]
    completed = chapter >= int(state["totalChapters"])
    return {
        **state,
        "currentChapterIndex": chapter,
        "status": "completed" if completed else "active",
        "chapterSummaries": summaries,
        "chapterContinuityUpdates": updates,
        "continuitySummary": " | ".join(summaries[-6:]),
        "lastChapterSummary": summary,
        "openLoops": [] if completed else _as_list(update.get("openLoops")),
        "resolvedLoops": _as_list(state.get("resolvedLoops")) + _as_list(update.get("resolvedLoops")),
        "importantObjects": _as_list(state.get("importantObjects")) + _as_list(update.get("objectsIntroduced")),
        "emotionalProgression": _as_list(state.get("emotionalProgression")) + _as_list([update.get("emotionalStep") or ""]),
        "antiRepetitionMemory": _as_list(state.get("antiRepetitionMemory")) + _as_list(update.get("thingsToAvoidRepeating")),
        "nextChapterGoal": "Serie terminee" if completed else str(update.get("nextChapterGoal") or ""),
        "relations": ((state.get("relations") or []) + (update.get("relations") or []))[-24:],
        "mysteries": ((state.get("mysteries") or []) + (update.get("mysteries") or []))[-24:],
        "narrativeObjects": ((state.get("narrativeObjects") or []) + (update.get("narrativeObjects") or []))[-32:],
        "emotions": update.get("emotions") or state.get("emotions") or {},
        "majorEvents": ((state.get("majorEvents") or []) + (update.get("majorEvents") or []))[-40:],
        "doNotRepeat": (_as_list(state.get("doNotRepeat")) + _as_list(update.get("doNotRepeat")))[-40:],
        "updatedAt": now,
        "completedAt": now if completed else None,
    }


def _notify_story_ready(db, *, user_id: str, child_name: str, story_id: str) -> int:
    try:
        from firebase_admin import messaging

        docs = db.collection("notification_devices").where("userId", "==", user_id).stream()
        tokens = [str(snap.to_dict().get("token") or "").strip() for snap in docs]
        tokens = [token for token in tokens if token]
        if not tokens:
            return 0
        message = messaging.MulticastMessage(
            tokens=tokens[:500],
            notification=messaging.Notification(
                title=f"Une nouvelle aventure attend {child_name}",
                body="L'histoire de ce soir est prete. Ouvrez Elunai et laissez la magie commencer.",
            ),
            data={"storyId": story_id, "route": f"/story?id={story_id}"},
        )
        return messaging.send_each_for_multicast(message).success_count
    except Exception:
        logger.exception("FCM notification failed for user %s", user_id)
        return 0


def _publish_for_child(db, child: dict[str, Any], *, date_key: str, now: datetime) -> str:
    child_id = str(child.get("id") or "").strip()
    user_id = str(child.get("userId") or "").strip()
    if not child_id or not user_id:
        return "invalid"
    story_id = _story_doc_id(child_id, user_id, date_key)
    story_ref = db.collection("stories").document(story_id)
    if story_ref.get().exists:
        return "skipped"

    serialized = child.get("storyFormat") == "serializedChapters"
    state_ref = db.collection("child_series_state").document(_state_doc_id(child_id, user_id))
    state = None
    if serialized:
        snap = state_ref.get()
        state = snap.to_dict() if snap.exists else None
        if not state or state.get("status") != "active" or int(state.get("currentChapterIndex") or 0) >= int(state.get("totalChapters") or 7):
            bible_payload = {
                "kind": "series_bible",
                "user": {"id": user_id},
                "child": child,
                "dateKey": date_key,
                "totalChapters": max(1, int(child.get("seriesDurationDays") or 7)),
                "ageYears": _age_years(child, now),
            }
            state = _new_series_state(
                child=child,
                user_id=user_id,
                date_key=date_key,
                bible=generate_series_bible(bible_payload),
                now=now,
            )
        generation_child = state.get("profileSnapshot") or child
        chapter = int(state.get("currentChapterIndex") or 0) + 1
        total = int(state.get("totalChapters") or 7)
        series_id = str(state["seriesId"])
        plan = next((item for item in state.get("chapterPlan", []) if item.get("chapterIndex") == chapter), None)
    else:
        generation_child, chapter, total, series_id, plan = child, 1, 1, None, None

    payload = {
        "kind": "story",
        "user": {"id": user_id},
        "child": generation_child,
        "dateKey": date_key,
        "ageYears": _age_years(child, now),
        "chapterIndex": chapter,
        "totalChapters": total,
        "seriesId": series_id,
        "continuityContext": state.get("continuitySummary") if state else None,
        "seriesBible": _series_bible(state) if state else None,
        "currentChapterPlan": plan,
    }
    generated = generate_story(payload)
    model_used = str(generated.get("modelUsed") or "unknown")
    prompt_tokens = int(generated.get("promptTokens") or 0)
    completion_tokens = int(generated.get("completionTokens") or 0)
    estimated_cost = estimate_cost(model_used, prompt_tokens, completion_tokens)
    generated["estimatedCost"] = estimated_cost
    persist_generation_metrics(
        db,
        StoryGenerationMetrics(
            user_id=user_id,
            child_id=child_id,
            story_id=story_id,
            model_used=model_used,
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=int(generated.get("totalTokens") or prompt_tokens + completion_tokens),
            estimated_cost=estimated_cost,
            generation_time_ms=int(generated.get("generationTimeMs") or 0),
            quality_score=int(generated.get("qualityScore") or 0),
            rewrite_attempts=int(generated.get("rewriteAttempts") or 0),
            fallback_used=bool(generated.get("fallbackUsed")),
        ),
    )
    batch = db.batch()
    batch.set(
        story_ref,
        {
            "id": story_id,
            "childId": child_id,
            "userId": user_id,
            "dateKey": date_key,
            "title": generated["title"],
            "content": generated["content"],
            "summary": generated["summary"],
            "theme": generated["theme"],
            "tone": generated["tone"],
            "estimatedReadingMinutes": generated["estimatedReadingMinutes"],
            "format": "serializedChapters" if serialized else "dailyStandalone",
            "chapterNumber": chapter,
            "totalChapters": total,
            "seriesId": series_id,
            "generationSource": generated.get("generationSource", "backend"),
            "qualityScore": generated.get("qualityScore", 0),
            "qualityDetails": generated.get("qualityDetails", {}),
            "qualityWarnings": generated.get("qualityWarnings", []),
            "coverImageUrl": generated.get("coverImageUrl"),
            "coverImageStatus": generated.get("coverImageStatus", "pending"),
            "coverPrompt": generated.get("coverPrompt"),
            "audioStatus": generated.get("audioStatus", "unavailable"),
            "audioUrl": generated.get("audioUrl"),
            "audioVoice": generated.get("audioVoice"),
            "audioDuration": generated.get("audioDuration"),
            "createdAt": now,
        },
    )
    if state:
        batch.set(state_ref, _advance_state(state, generated, chapter, now), merge=True)
    batch.commit()
    _notify_story_ready(db, user_id=user_id, child_name=str(child.get("firstName") or "votre enfant"), story_id=story_id)
    return "created"


def publish_daily_stories(*, current_time: datetime | None = None) -> dict[str, int | str]:
    now = current_time or datetime.now(timezone.utc)
    local_now = now.astimezone(LOCAL_TIMEZONE)
    date_key = local_now.strftime("%Y-%m-%d")
    limit = max(1, int(os.getenv("DAILY_STORY_MAX_PROFILES", "500")))
    db = firestore_client()
    results = {"created": 0, "skipped": 0, "invalid": 0, "failed": 0}
    user_profile_counts: dict[str, int] = {}
    user_limits: dict[str, int] = {}
    for index, snap in enumerate(db.collection("children_profiles").stream()):
        if index >= limit:
            break
        try:
            child = snap.to_dict()
            uid = str(child.get("userId") or "")
            if uid not in user_limits:
                user_limits[uid] = max_children_for_user(db, uid)
            user_profile_counts[uid] = user_profile_counts.get(uid, 0) + 1
            if user_profile_counts[uid] > user_limits[uid]:
                results["skipped"] += 1
                continue
            result = _publish_for_child(db, child, date_key=date_key, now=now)
            results[result] += 1
        except Exception:
            results["failed"] += 1
            logger.exception("Daily story publication failed for profile %s", snap.id)
    return {"dateKey": date_key, **results}
