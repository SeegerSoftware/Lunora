from datetime import datetime, timezone

from fastapi import HTTPException
from google.cloud.firestore_v1 import transactional

from .auth import firestore_client


def reserve_daily_story(uid: str, child_id: str, date_key: str) -> None:
    db = firestore_client()
    ref = db.collection("story_daily_quotas").document(f"{uid}_{child_id}_{date_key}")
    story_ref = db.collection("stories").document(f"story_{uid}_{child_id}_{date_key}")

    @transactional
    def reserve(transaction) -> None:
        snap = ref.get(transaction=transaction)
        published = story_ref.get(transaction=transaction)
        if snap.exists or published.exists:
            raise HTTPException(status_code=429, detail="Daily story quota reached for this child")
        transaction.set(
            ref,
            {
                "uid": uid,
                "childId": child_id,
                "dateKey": date_key,
                "reservedAt": datetime.now(timezone.utc),
            },
        )

    reserve(db.transaction())
