import os

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

from .account import delete_account_data
from .auth import verify_app_check, verify_firebase_user
from .models import StoryGenerationPayload, StripeCheckoutPayload
from .rate_limit import check_generation_rate_limit
from .story_generation import generate_series_bible, generate_story
from .stripe_checkout import create_checkout_session
from .subscriptions import handle_stripe_webhook

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
    child_user_id = data.get("child", {}).get("userId")
    if child_user_id and child_user_id != firebase_user.get("uid"):
        raise HTTPException(status_code=403, detail="Child profile does not belong to token user")

    if data.get("user", {}).get("id") != firebase_user.get("uid"):
        # The mobile client sends its current user model; the Firebase token is authoritative.
        data = {**data, "user": {**data.get("user", {}), "id": firebase_user.get("uid")}}

    check_generation_rate_limit(str(firebase_user.get("uid")))

    kind = str(data.get("kind") or "story")
    if kind == "series_bible":
        return {"result": generate_series_bible(data)}
    if kind == "story":
        return {"result": generate_story(data)}
    raise HTTPException(status_code=400, detail="Unsupported generation kind")


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
