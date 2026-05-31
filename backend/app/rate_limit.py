import os
import time
from datetime import datetime, timedelta, timezone
from hashlib import sha256

from fastapi import HTTPException
from google.cloud.firestore_v1 import transactional

from .auth import firestore_client


def check_generation_rate_limit(uid: str, *, now_seconds: float | None = None) -> None:
    limit = int(os.getenv("GENERATION_RATE_LIMIT_PER_HOUR", "12"))
    window_seconds = int(os.getenv("GENERATION_RATE_LIMIT_WINDOW_SECONDS", "3600"))
    if limit <= 0:
        return
    if not uid:
        raise HTTPException(status_code=401, detail="Firebase uid is required")

    now = int(time.time() if now_seconds is None else now_seconds)
    bucket_start = now - (now % window_seconds)
    bucket_id = sha256(f"{uid}:{bucket_start}:{window_seconds}".encode()).hexdigest()
    db = firestore_client()
    ref = db.collection("generation_rate_limits").document(bucket_id)

    @transactional
    def reserve(transaction) -> None:
        snapshot = ref.get(transaction=transaction)
        count = int(snapshot.get("count")) if snapshot.exists else 0
        if count >= limit:
            raise HTTPException(status_code=429, detail="Generation rate limit exceeded")
        start = datetime.fromtimestamp(bucket_start, timezone.utc)
        transaction.set(
            ref,
            {
                "uid": uid,
                "count": count + 1,
                "bucketStart": start,
                "expiresAt": start + timedelta(seconds=window_seconds * 2),
            },
            merge=True,
        )

    reserve(db.transaction())
