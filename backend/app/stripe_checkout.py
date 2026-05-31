import os
from typing import Any

from fastapi import HTTPException
from .plans import PLANS, normalize_plan_id


def create_checkout_session(payload: dict[str, Any], firebase_user: dict[str, Any]) -> dict[str, str]:
    secret_key = os.getenv("STRIPE_SECRET_KEY", "").strip()
    success_url = os.getenv("STRIPE_SUCCESS_URL", "https://lunora.app/#/subscription/success")
    cancel_url = os.getenv("STRIPE_CANCEL_URL", "https://lunora.app/#/subscription/cancel")
    requested_plan_id = str(payload.get("planId") or "plan_solo")
    if requested_plan_id not in {*PLANS, "plan_elunai", "plan_5", "plan_10", "plan_15"}:
        raise HTTPException(status_code=400, detail="Unsupported Stripe plan")
    plan_id = normalize_plan_id(requested_plan_id)
    price_env = "STRIPE_PRICE_ID_SOLO" if plan_id == "plan_solo" else "STRIPE_PRICE_ID_FAMILY"
    price_id = os.getenv(price_env, "").strip()

    if os.getenv("STRIPE_MOCK", "").lower() == "true":
        return {"url": "https://checkout.stripe.com/mock-session"}

    if not secret_key or not price_id:
        raise HTTPException(status_code=503, detail="Stripe Checkout is not configured")

    try:
        import stripe
    except Exception as exc:  # pragma: no cover - dependency/runtime config
        raise HTTPException(status_code=503, detail="stripe package is not installed") from exc

    stripe.api_key = secret_key
    email = str(firebase_user.get("email") or payload.get("email") or "").strip() or None

    session = stripe.checkout.Session.create(
        mode="subscription",
        customer_email=email,
        line_items=[{"price": price_id, "quantity": 1}],
        success_url=success_url,
        cancel_url=cancel_url,
        subscription_data={
            "metadata": {
                "firebaseUid": str(firebase_user.get("uid") or ""),
                "planId": plan_id,
            }
        },
        metadata={
            "firebaseUid": str(firebase_user.get("uid") or ""),
            "planId": plan_id,
        },
    )
    return {"url": session.url}
