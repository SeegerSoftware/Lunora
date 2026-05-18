import os
import time
from collections import defaultdict, deque

from fastapi import HTTPException


_events: dict[str, deque[float]] = defaultdict(deque)


def check_generation_rate_limit(uid: str) -> None:
    limit = int(os.getenv("GENERATION_RATE_LIMIT_PER_HOUR", "12"))
    window_seconds = int(os.getenv("GENERATION_RATE_LIMIT_WINDOW_SECONDS", "3600"))
    now = time.time()
    bucket = _events[uid]
    while bucket and bucket[0] <= now - window_seconds:
        bucket.popleft()
    if len(bucket) >= limit:
        raise HTTPException(status_code=429, detail="Generation rate limit exceeded")
    bucket.append(now)
