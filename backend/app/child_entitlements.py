from typing import Any

from fastapi import HTTPException

from .plans import plan_config


def max_children_for_user(db, uid: str) -> int:
    snap = db.collection("users").document(uid).get()
    data: dict[str, Any] = snap.to_dict() if snap.exists else {}
    stored = data.get("maxChildren")
    if isinstance(stored, int) and stored > 0:
        return stored
    return int(plan_config(data.get("selectedPlan"))["maxChildren"])


def assert_child_is_within_plan(db, uid: str, child_id: str) -> None:
    profiles = [
        snap.id
        for snap in db.collection("children_profiles").where("userId", "==", uid).stream()
    ]
    profiles.sort()
    allowed = set(profiles[: max_children_for_user(db, uid)])
    if child_id not in allowed:
        raise HTTPException(status_code=403, detail="Child profile exceeds subscription limit")
