from typing import Any


PLANS: dict[str, dict[str, Any]] = {
    "plan_solo": {"subscriptionPlan": "solo", "maxChildren": 1, "dailyStoriesPerChild": 1},
    "plan_family": {"subscriptionPlan": "family", "maxChildren": 4, "dailyStoriesPerChild": 1},
}


def normalize_plan_id(raw: str | None) -> str:
    value = (raw or "").strip()
    return value if value in PLANS else "plan_solo"


def plan_config(raw: str | None) -> dict[str, Any]:
    return PLANS[normalize_plan_id(raw)]
