import os

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware

from .auth import verify_firebase_user
from .story_generation import generate_series_bible, generate_story
from .stripe_checkout import create_checkout_session
from .subscriptions import handle_stripe_webhook

app = FastAPI(
    title="Elunai API",
    version="0.1.0",
    description="Backend minimal Elunai (FastAPI).",
)

def _cors_origins() -> list[str]:
    raw = os.getenv("CORS_ALLOWED_ORIGINS", "").strip()
    if not raw:
        return ["http://localhost:3000", "http://localhost:5173"]
    return [origin.strip() for origin in raw.split(",") if origin.strip()]


app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins(),
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
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
    payload: dict,
    firebase_user: dict = Depends(verify_firebase_user),
):
    child_user_id = payload.get("child", {}).get("userId")
    if child_user_id and child_user_id != firebase_user.get("uid"):
        raise HTTPException(status_code=403, detail="Child profile does not belong to token user")

    if payload.get("user", {}).get("id") != firebase_user.get("uid"):
        # The mobile client sends its current user model; the Firebase token is authoritative.
        payload = {**payload, "user": {**payload.get("user", {}), "id": firebase_user.get("uid")}}

    kind = str(payload.get("kind") or "story")
    if kind == "series_bible":
        return {"result": generate_series_bible(payload)}
    if kind == "story":
        return {"result": generate_story(payload)}
    raise HTTPException(status_code=400, detail="Unsupported generation kind")


@app.post("/stripe/checkout")
def stripe_checkout(
    payload: dict,
    firebase_user: dict = Depends(verify_firebase_user),
):
    return create_checkout_session(payload, firebase_user)


@app.post("/stripe/webhook")
async def stripe_webhook(request: Request):
    return await handle_stripe_webhook(request)
