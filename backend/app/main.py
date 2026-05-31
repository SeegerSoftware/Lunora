import os
from datetime import datetime
from zoneinfo import ZoneInfo

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

from .account import delete_account_data
from .child_entitlements import assert_child_is_within_plan
from .auth import firestore_client, verify_app_check, verify_firebase_user
from .models import StoryGenerationPayload, StripeCheckoutPayload
from .rate_limit import check_generation_rate_limit
from .daily_stories import publish_daily_stories
from .generation_metrics import (
    StoryGenerationMetrics,
    estimate_cost,
    persist_generation_metrics,
)
from .scheduler_auth import verify_scheduler_request
from .story_generation import generate_series_bible, generate_story
from .stripe_checkout import create_checkout_session
from .subscriptions import handle_stripe_webhook
from .story_quotas import reserve_daily_story

app = FastAPI(
    title="Elunai API",
    version="0.1.0",
    description="Backend minimal Elunai (FastAPI).",
)


@app.middleware("http")
async def reject_oversized_requests(request: Request, call_next):
    limit = int(os.getenv("MAX_REQUEST_BODY_BYTES", "131072"))
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > limit:
        return JSONResponse(status_code=413, content={"detail": "Request body is too large"})
    return await call_next(request)


def _cors_origins() -> list[str]:
    raw = os.getenv("CORS_ALLOWED_ORIGINS", "").strip()
    if not raw:
        return ["http://localhost:3000", "http://localhost:5173"]
    return [
        origin.strip()
        for origin in raw.replace("|", ",").replace(";", ",").split(",")
        if origin.strip()
    ]


app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins(),
    allow_credentials=True,
    allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Firebase-AppCheck"],
)


@app.get("/health")
def health():
    return {"ok": True}


@app.get("/mobile/config")
def mobile_config():
    return {
        "appName": "Elunai",
        "minAppVersion": "1.0.0",
        "serverDrivenUiVersion": 1,
        "features": {
            "useServerApi": True,
        },
    }


@app.post("/stories/generate")
def stories_generate(
    payload: StoryGenerationPayload,
    firebase_user: dict = Depends(verify_firebase_user),
    _: None = Depends(verify_app_check),
):
    data = payload.model_dump(mode="json", exclude_none=True)
    uid = str(firebase_user.get("uid") or "")
    child_id = str(data.get("childId") or data.get("child", {}).get("id") or "").strip()
    child_user_id = data.get("child", {}).get("userId")
    if child_user_id and child_user_id != firebase_user.get("uid"):
        raise HTTPException(status_code=403, detail="Child profile does not belong to token user")

    if data.get("user", {}).get("id") != firebase_user.get("uid"):
        # The mobile client sends its current user model; the Firebase token is authoritative.
        data = {**data, "user": {**data.get("user", {}), "id": firebase_user.get("uid")}}

    is_mock = os.getenv("OPENAI_MOCK", "").lower() == "true"
    if not is_mock:
        if not child_id:
            raise HTTPException(status_code=422, detail="childId is required")
        db = firestore_client()
        snap = db.collection("children_profiles").document(child_id).get()
        child = snap.to_dict() if snap.exists else None
        if not child or child.get("userId") != uid:
            raise HTTPException(status_code=403, detail="Child profile does not belong to token user")
        assert_child_is_within_plan(db, uid, child_id)
        data = {**data, "childId": child_id, "child": {**child, "id": child_id}}

    check_generation_rate_limit(uid)

    kind = str(data.get("kind") or "story")
    if kind == "series_bible":
        return {"result": generate_series_bible(data)}
    if kind == "story":
        if not is_mock and not firebase_user.get("admin"):
            date_key = datetime.now(ZoneInfo("Europe/Zurich")).strftime("%Y-%m-%d")
            reserve_daily_story(uid, child_id, date_key)
        result = generate_story(data)
        prompt_tokens = int(result.get("promptTokens") or 0)
        completion_tokens = int(result.get("completionTokens") or 0)
        model_used = str(result.get("modelUsed") or "unknown")
        estimated_cost = estimate_cost(model_used, prompt_tokens, completion_tokens)
        result["estimatedCost"] = estimated_cost
        if not is_mock:
            persist_generation_metrics(
                firestore_client(),
                StoryGenerationMetrics(
                user_id=uid,
                child_id=child_id,
                story_id=f"story_{uid}_{child_id}_{data.get('dateKey') or 'on-demand'}",
                model_used=model_used,
                prompt_tokens=prompt_tokens,
                completion_tokens=completion_tokens,
                total_tokens=int(result.get("totalTokens") or prompt_tokens + completion_tokens),
                estimated_cost=estimated_cost,
                generation_time_ms=int(result.get("generationTimeMs") or 0),
                quality_score=int(result.get("qualityScore") or 0),
                rewrite_attempts=int(result.get("rewriteAttempts") or 0),
                fallback_used=bool(result.get("fallbackUsed")),
                ),
            )
        return {"result": result}
    raise HTTPException(status_code=400, detail="Unsupported generation kind")


@app.post("/internal/daily-stories/publish")
def daily_stories_publish(_: None = Depends(verify_scheduler_request)):
    return publish_daily_stories()


@app.post("/stripe/checkout")
def stripe_checkout(
    payload: StripeCheckoutPayload,
    firebase_user: dict = Depends(verify_firebase_user),
    _: None = Depends(verify_app_check),
):
    return create_checkout_session(payload.model_dump(exclude_none=True), firebase_user)


@app.delete("/account")
def delete_account(
    firebase_user: dict = Depends(verify_firebase_user),
    _: None = Depends(verify_app_check),
):
    return {"ok": True, "deleted": delete_account_data(str(firebase_user.get("uid")))}


@app.post("/stripe/webhook")
async def stripe_webhook(request: Request):
    return await handle_stripe_webhook(request)
