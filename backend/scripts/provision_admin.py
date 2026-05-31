"""Provision an Elunai administrator account without embedding credentials."""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, timezone
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_DIR))

from app.auth import _firebase_auth, firestore_client  # noqa: E402


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create or promote an Elunai Firebase account to administrator.",
    )
    parser.add_argument("--email", required=True, help="Administrator email address.")
    parser.add_argument(
        "--create-if-missing",
        action="store_true",
        help="Create the Firebase Auth user if the email does not exist.",
    )
    return parser.parse_args()


def provision_admin(email: str, *, create_if_missing: bool) -> tuple[str, bool]:
    normalized_email = email.strip().lower()
    if not normalized_email:
        raise ValueError("Email is required")

    firebase_auth = _firebase_auth()
    created = False
    try:
        firebase_user = firebase_auth.get_user_by_email(normalized_email)
    except firebase_auth.UserNotFoundError:
        if not create_if_missing:
            raise RuntimeError(
                "Firebase account not found. Re-run with --create-if-missing "
                "or create the account through the app first."
            )
        firebase_user = firebase_auth.create_user(
            email=normalized_email,
            email_verified=True,
            disabled=False,
        )
        created = True

    claims = dict(firebase_user.custom_claims or {})
    claims["admin"] = True
    firebase_auth.set_custom_user_claims(firebase_user.uid, claims)

    now = datetime.now(timezone.utc)
    db = firestore_client()
    db.collection("users").document(firebase_user.uid).set(
        {
            "id": firebase_user.uid,
            "email": normalized_email,
            "createdAt": firebase_user.user_metadata.creation_timestamp
            and datetime.fromtimestamp(
                firebase_user.user_metadata.creation_timestamp / 1000,
                tz=timezone.utc,
            )
            or now,
            "selectedPlan": "plan_elunai",
            "subscriptionStatus": "active",
            "isAdmin": True,
            "updatedAt": now,
        },
        merge=True,
    )
    db.collection("subscriptions").document(firebase_user.uid).set(
        {
            "userId": firebase_user.uid,
            "planId": "plan_elunai",
            "status": "active",
            "startedAt": now,
            "endsAt": None,
            "renewalType": "monthly",
            "accessSource": "admin_provisioning",
            "updatedAt": now,
        },
        merge=True,
    )
    return firebase_user.uid, created


def main() -> int:
    args = _parse_args()
    uid, created = provision_admin(
        args.email,
        create_if_missing=args.create_if_missing,
    )
    verb = "created and provisioned" if created else "provisioned"
    print(f"Admin account {verb}: uid={uid}")
    print("Sign out and sign back in so Firebase refreshes the ID token claims.")
    return 0


if __name__ == "__main__":
    os.chdir(BACKEND_DIR)
    raise SystemExit(main())
