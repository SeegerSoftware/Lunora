import os
from functools import lru_cache

from fastapi import Depends, Header, HTTPException


@lru_cache(maxsize=1)
def _firebase_auth():
    try:
        import firebase_admin
        from firebase_admin import auth, credentials
    except Exception as exc:  # pragma: no cover - dependency/runtime config
        raise RuntimeError("firebase-admin is not installed") from exc

    if not firebase_admin._apps:
        credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "").strip()
        project_id = os.getenv("FIREBASE_PROJECT_ID", "").strip()
        options = {"projectId": project_id} if project_id else None
        if credentials_path:
            firebase_admin.initialize_app(
                credentials.Certificate(credentials_path),
                options=options,
            )
        else:
            firebase_admin.initialize_app(options=options)
    return auth


def verify_firebase_user(authorization: str | None = Header(default=None)) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Firebase ID token required")

    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(status_code=401, detail="Firebase ID token required")

    if os.getenv("ALLOW_TEST_BEARER_TOKEN") == "true" and token.startswith("test:"):
        uid = token.removeprefix("test:") or "test-user"
        return {"uid": uid, "email": f"{uid}@example.test"}

    try:
        return _firebase_auth().verify_id_token(token)
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid Firebase ID token") from exc


FirebaseUser = Depends(verify_firebase_user)


def verify_app_check(x_firebase_appcheck: str | None = Header(default=None)) -> None:
    enforced = os.getenv("APP_CHECK_ENFORCED", "").lower() == "true"
    if os.getenv("ALLOW_TEST_APP_CHECK") == "true" and x_firebase_appcheck == "test":
        return
    if not x_firebase_appcheck:
        if enforced:
            raise HTTPException(status_code=401, detail="Firebase App Check token required")
        return
    try:
        from firebase_admin import app_check

        _firebase_auth()
        app_check.verify_token(x_firebase_appcheck)
    except Exception as exc:
        if enforced:
            raise HTTPException(status_code=401, detail="Invalid Firebase App Check token") from exc


AppCheck = Depends(verify_app_check)


def firestore_client():
    try:
        from firebase_admin import firestore
    except Exception as exc:  # pragma: no cover - dependency/runtime config
        raise RuntimeError("firebase-admin is not installed") from exc

    _firebase_auth()
    return firestore.client()
