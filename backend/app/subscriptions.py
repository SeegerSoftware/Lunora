import os
from datetime import datetime, timezone
from typing import Any

from fastapi import HTTPException, Request

from .auth import firestore_client


ACTIVE_STATUSES = {"active", "trialing"}
GRACE_STATUSES = {"past_due", "unpaid"}
CANCELED_STATUSES = {"canceled", "incomplete", "incomplete_expired", "paused"}


def _unix_to_datetime(value: Any) -> datetime | None:
    if value is None:
        return None
    try:
        return datetime.fromtimestamp(int(value), tz=timezone.utc)
    except Exception:
        return None


def _status_from_stripe(raw: str | None) -> str:
    value = (raw or "").strip()
    if value in ACTIVE_STATUSES:
        return "active"
    if value in GRACE_STATUSES:
        return "grace"
    if value in CANCELED_STATUSES:
        return "canceled"
    return "none"


def _plan_id_from_subscription(subscription: dict[str, Any]) -> str:
    metadata_plan = str(subscription.get("metadata", {}).get("planId") or "").strip()
    if metadata_plan:
        return metadata_plan
    return os.getenv("STRIPE_DEFAULT_PLAN_ID", "plan_elunai")


def _uid_from_subscription(subscription: dict[str, Any]) -> str:
    uid = str(subscription.get("metadata", {}).get("firebaseUid") or "").strip()
    if not uid:
        raise HTTPException(status_code=400, detail="Stripe subscription missing firebaseUid metadata")
    return uid


def _write_subscription(subscription: dict[str, Any]) -> None:
    uid = _uid_from_subscription(subscription)
    status = _status_from_stripe(subscription.get("status"))
    plan_id = _plan_id_from_subscription(subscription)
    started_at = _unix_to_datetime(subscription.get("start_date")) or datetime.now(timezone.utc)
    ends_at = _unix_to_datetime(subscription.get("current_period_end"))

    db = firestore_client()
    sub_doc = {
        "userId": uid,
        "planId": plan_id,
        "status": status,
        "startedAt": started_at,
        "endsAt": ends_at,
        "renewalType": "monthly",
        "stripeCustomerId": subscription.get("customer"),
        "stripeSubscriptionId": subscription.get("id"),
        "updatedAt": datetime.now(timezone.utc),
    }
    user_doc = {
        "selectedPlan": plan_id if status in {"active", "grace"} else None,
        "subscriptionStatus": status,
        "updatedAt": datetime.now(timezone.utc),
    }
    db.collection("subscriptions").document(uid).set(sub_doc, merge=True)
    db.collection("users").document(uid).set(user_doc, merge=True)


def _delete_or_cancel_subscription(subscription: dict[str, Any]) -> None:
    uid = _uid_from_subscription(subscription)
    plan_id = _plan_id_from_subscription(subscription)
    db = firestore_client()
    db.collection("subscriptions").document(uid).set(
        {
            "userId": uid,
            "planId": plan_id,
            "status": "canceled",
            "endsAt": _unix_to_datetime(subscription.get("ended_at"))
            or _unix_to_datetime(subscription.get("current_period_end")),
            "renewalType": "monthly",
            "stripeCustomerId": subscription.get("customer"),
            "stripeSubscriptionId": subscription.get("id"),
            "updatedAt": datetime.now(timezone.utc),
        },
        merge=True,
    )
    db.collection("users").document(uid).set(
        {
            "selectedPlan": None,
            "subscriptionStatus": "canceled",
            "updatedAt": datetime.now(timezone.utc),
        },
        merge=True,
    )


async def handle_stripe_webhook(request: Request) -> dict[str, bool | str]:
    body = await request.body()
    signature = request.headers.get("stripe-signature")
    event: dict[str, Any]

    if os.getenv("STRIPE_MOCK", "").lower() == "true":
        event = await request.json()
    else:
        secret = os.getenv("STRIPE_WEBHOOK_SECRET", "").strip()
        if not secret:
            raise HTTPException(status_code=503, detail="STRIPE_WEBHOOK_SECRET is not configured")
        if not signature:
            raise HTTPException(status_code=400, detail="Missing Stripe signature")
        try:
            import stripe

            event = stripe.Webhook.construct_event(body, signature, secret)
        except Exception as exc:
            raise HTTPException(status_code=400, detail="Invalid Stripe webhook signature") from exc

    event_type = str(event.get("type") or "")
    obj = event.get("data", {}).get("object", {})
    if not isinstance(obj, dict):
        raise HTTPException(status_code=400, detail="Invalid Stripe webhook object")

    if event_type in {"checkout.session.completed"}:
        subscription_id = obj.get("subscription")
        if not subscription_id:
            return {"ok": True, "ignored": "checkout.session without subscription"}
        if os.getenv("STRIPE_MOCK", "").lower() == "true":
            sub = {
                "id": subscription_id,
                "customer": obj.get("customer"),
                "status": "active",
                "start_date": obj.get("created"),
                "current_period_end": obj.get("expires_at"),
                "metadata": obj.get("metadata", {}),
            }
        else:
            import stripe

            stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "").strip()
            sub = stripe.Subscription.retrieve(subscription_id)
            if not getattr(sub, "metadata", None):
                sub["metadata"] = obj.get("metadata", {})
        _write_subscription(dict(sub))
        return {"ok": True, "handled": event_type}

    if event_type in {"customer.subscription.created", "customer.subscription.updated"}:
        _write_subscription(obj)
        return {"ok": True, "handled": event_type}

    if event_type in {"customer.subscription.deleted"}:
        _delete_or_cancel_subscription(obj)
        return {"ok": True, "handled": event_type}

    return {"ok": True, "ignored": event_type}
