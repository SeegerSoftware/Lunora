import os

from fastapi import Header, HTTPException


def verify_scheduler_request(authorization: str | None = Header(default=None)) -> None:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Scheduler OIDC token required")
    token = authorization.removeprefix("Bearer ").strip()
    if os.getenv("ALLOW_TEST_SCHEDULER_TOKEN") == "true" and token == "test:scheduler":
        return

    audience = os.getenv("SCHEDULER_AUDIENCE", "").strip()
    service_account = os.getenv("SCHEDULER_SERVICE_ACCOUNT_EMAIL", "").strip()
    if not audience or not service_account:
        raise HTTPException(status_code=503, detail="Scheduler authentication is not configured")
    try:
        from google.auth.transport import requests
        from google.oauth2 import id_token

        claims = id_token.verify_oauth2_token(token, requests.Request(), audience=audience)
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid scheduler OIDC token") from exc
    if claims.get("email") != service_account:
        raise HTTPException(status_code=403, detail="Unexpected scheduler service account")
