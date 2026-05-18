from datetime import datetime, timezone

from fastapi import HTTPException

from .auth import firestore_client, _firebase_auth


USER_SCOPED_COLLECTIONS = [
    "children_profiles",
    "stories",
    "child_series_state",
    "story_worlds",
    "story_memory_snapshots",
]


def _delete_query_results(query) -> int:
    deleted = 0
    for snap in query.stream():
        snap.reference.delete()
        deleted += 1
    return deleted


def delete_account_data(uid: str) -> dict[str, int | bool]:
    if not uid:
        raise HTTPException(status_code=400, detail="uid required")

    db = firestore_client()
    counts: dict[str, int | bool] = {}
    for collection in USER_SCOPED_COLLECTIONS:
        counts[collection] = _delete_query_results(
            db.collection(collection).where("userId", "==", uid)
        )

    db.collection("subscriptions").document(uid).delete()
    counts["subscriptions"] = 1

    db.collection("users").document(uid).set(
        {
            "deletedAt": datetime.now(timezone.utc),
            "subscriptionStatus": "none",
            "selectedPlan": None,
        },
        merge=True,
    )
    db.collection("users").document(uid).delete()
    counts["users"] = 1

    try:
        _firebase_auth().delete_user(uid)
        counts["authUserDeleted"] = True
    except Exception as exc:
        raise HTTPException(status_code=502, detail="Firebase Auth deletion failed") from exc

    return counts
