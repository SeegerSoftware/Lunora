import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

os.environ["ALLOW_TEST_BEARER_TOKEN"] = "true"
os.environ["OPENAI_MOCK"] = "true"
os.environ["STRIPE_MOCK"] = "true"
os.environ["FIRESTORE_EMULATOR_HOST"] = "localhost:8080"
os.environ["ALLOW_TEST_APP_CHECK"] = "true"
os.environ["ALLOW_TEST_SCHEDULER_TOKEN"] = "true"
os.environ["GENERATION_RATE_LIMIT_PER_HOUR"] = "0"

from app.main import app  # noqa: E402
from app.rate_limit import check_generation_rate_limit  # noqa: E402
from app.plans import normalize_plan_id, plan_config  # noqa: E402
from app.child_entitlements import assert_child_is_within_plan  # noqa: E402
from app.daily_stories import _publish_for_child  # noqa: E402
from app.story_generation import (  # noqa: E402
    _corrective_story_prompt,
    _mock_story,
    _normalize_story,
    _story_prompt,
    _story_quality_issues,
)
from scripts.provision_admin import provision_admin  # noqa: E402


client = TestClient(app)


def test_subscription_plans_are_limited_to_solo_and_family():
    assert plan_config("plan_solo")["maxChildren"] == 1
    assert plan_config("plan_family")["maxChildren"] == 4
    assert normalize_plan_id("plan_elunai") == "plan_solo"


def test_solo_rejects_a_second_child_profile():
    class FakeSnap:
        def __init__(self, doc_id, data):
            self.id = doc_id
            self._data = data

        @property
        def exists(self):
            return self._data is not None

        def to_dict(self):
            return self._data

    class FakeQuery:
        def stream(self):
            return [
                FakeSnap("child-1", {"userId": "user-1"}),
                FakeSnap("child-2", {"userId": "user-1"}),
            ]

    class FakeCollection:
        def __init__(self, name):
            self.name = name

        def document(self, _doc_id):
            class FakeDoc:
                def get(self):
                    return FakeSnap("user-1", {"maxChildren": 1})

            return FakeDoc()

        def where(self, *_args):
            return FakeQuery()

    class FakeDb:
        def collection(self, name):
            return FakeCollection(name)

    assert_child_is_within_plan(FakeDb(), "user-1", "child-1")
    with pytest.raises(HTTPException) as exc:
        assert_child_is_within_plan(FakeDb(), "user-1", "child-2")
    assert exc.value.status_code == 403


def test_local_fallback_is_long_enough_for_mobile_validation():
    story = _mock_story(
        {
            "ageYears": 8,
            "child": {"firstName": "Lina", "storyLengthMinutes": 10},
        }
    )

    assert story["generationSource"] == "backend-fallback"
    assert 800 <= len(story["content"].split()) <= 1200
    assert _story_quality_issues(story["content"], "Lina") == []


def test_story_prompt_includes_minimum_length():
    prompt = _story_prompt(
        {
            "ageYears": 8,
            "child": {"firstName": "Lina", "storyLengthMinutes": 10},
        }
    )

    assert "entre 1000 et 1200 mots" in prompt
    assert "environ 1100 mots" in prompt
    assert "10 à 12 paragraphes" in prompt


@pytest.mark.parametrize(
    ("age", "expected"),
    [(1, (300, 400, 500)), (4, (600, 700, 800)), (6, (800, 900, 1000)),
     (8, (1000, 1100, 1200)), (10, (1200, 1500, 1800))],
)
def test_story_age_profiles_follow_product_ranges(age, expected):
    from app.story_generation import _story_word_bounds

    assert _story_word_bounds(age) == expected


def test_mock_story_exposes_quality_and_deferred_media_contract():
    story = _mock_story({"ageYears": 6, "child": {"firstName": "Lina"}})

    assert 0 <= story["qualityScore"] <= 100
    assert "structure" in story["qualityDetails"]
    assert story["coverImageStatus"] == "pending"
    assert story["coverPrompt"]
    assert story["audioStatus"] == "unavailable"


@pytest.mark.parametrize("word_count", [799, 1201])
def test_story_normalization_rejects_duration_outside_8_to_12_minutes(word_count):
    with pytest.raises(ValueError):
        _normalize_story(
            {"content": "mot " * word_count},
            {"child": {"storyLengthMinutes": 10}},
        )


def test_story_quality_rejects_duplicate_paragraph_and_raw_variable():
    story = _mock_story({"child": {"firstName": "Lina"}})
    content = story["content"].replace("Lina", "{{child_name}}")
    first_paragraph = content.split("\n\n")[0]
    content = f"{content}\n\n{first_paragraph}"

    issues = _story_quality_issues(content, "Lina")

    assert "un ou plusieurs paragraphes sont répétés" in issues
    assert "une variable brute non remplacée apparaît dans le texte" in issues
    assert "le prénom réel 'Lina' n'apparaît pas dans l'histoire" in issues


def test_corrective_prompt_lists_quality_failures():
    prompt = _corrective_story_prompt("PROMPT INITIAL", ["paragraphes répétés"])

    assert "PROMPT INITIAL" in prompt
    assert "paragraphes répétés" in prompt
    assert "Réécris entièrement l'histoire" in prompt


def test_rate_limit_is_shared_through_firestore(monkeypatch):
    state = {}

    class FakeSnap:
        @property
        def exists(self):
            return bool(state)

        def get(self, key):
            return state[key]

    class FakeRef:
        def get(self, transaction=None):
            return FakeSnap()

    class FakeCollection:
        def document(self, _doc_id):
            return FakeRef()

    class FakeTransaction:
        def set(self, _ref, values, merge=False):
            state.update(values)

    class FakeDb:
        def collection(self, _name):
            return FakeCollection()

        def transaction(self):
            return FakeTransaction()

    monkeypatch.setenv("GENERATION_RATE_LIMIT_PER_HOUR", "1")
    monkeypatch.setattr("app.rate_limit.firestore_client", lambda: FakeDb())
    monkeypatch.setattr("app.rate_limit.transactional", lambda fn: fn)

    check_generation_rate_limit("user-1", now_seconds=1_700_000_000)
    with pytest.raises(HTTPException) as exc:
        check_generation_rate_limit("user-1", now_seconds=1_700_000_001)

    assert exc.value.status_code == 429


def test_stories_generate_requires_firebase_token():
    response = client.post("/stories/generate", json={})

    assert response.status_code == 401


def test_daily_story_publish_requires_scheduler_token():
    response = client.post("/internal/daily-stories/publish")

    assert response.status_code == 401


def test_daily_story_publish_accepts_scheduler_token(monkeypatch):
    monkeypatch.setattr(
        "app.main.publish_daily_stories",
        lambda: {"dateKey": "2026-05-31", "created": 1},
    )

    response = client.post(
        "/internal/daily-stories/publish",
        headers={"Authorization": "Bearer test:scheduler"},
    )

    assert response.status_code == 200
    assert response.json()["created"] == 1


def test_daily_story_publication_is_idempotent(monkeypatch):
    documents = {}
    notifications = []

    class FakeSnap:
        def __init__(self, path):
            self.path = path

        @property
        def exists(self):
            return self.path in documents

        def to_dict(self):
            return documents.get(self.path)

    class FakeRef:
        def __init__(self, path):
            self.path = path

        def get(self):
            return FakeSnap(self.path)

    class FakeCollection:
        def __init__(self, name):
            self.name = name

        def document(self, doc_id):
            return FakeRef(f"{self.name}/{doc_id}")

    class FakeBatch:
        def __init__(self):
            self.writes = []

        def set(self, ref, values, merge=False):
            self.writes.append((ref.path, values, merge))

        def commit(self):
            for path, values, merge in self.writes:
                documents[path] = {**documents.get(path, {}), **values} if merge else values

    class FakeDb:
        def collection(self, name):
            return FakeCollection(name)

        def batch(self):
            return FakeBatch()

    monkeypatch.setattr(
        "app.daily_stories.generate_story",
        lambda _payload: {
            "title": "Histoire du soir",
            "content": "Contenu",
            "summary": "Resume",
            "theme": "Nature",
            "tone": "reassuring",
            "estimatedReadingMinutes": 10,
        },
    )
    monkeypatch.setattr(
        "app.daily_stories._notify_story_ready",
        lambda *_args, **kwargs: notifications.append(kwargs["story_id"]) or 1,
    )
    child = {
        "id": "child-1",
        "userId": "user-1",
        "firstName": "Lina",
        "storyFormat": "dailyStandalone",
    }
    now = datetime(2026, 5, 31, 10, 0, tzinfo=timezone.utc)

    assert _publish_for_child(FakeDb(), child, date_key="2026-05-31", now=now) == "created"
    assert _publish_for_child(FakeDb(), child, date_key="2026-05-31", now=now) == "skipped"
    assert notifications == ["story_user-1_child-1_2026-05-31"]


def test_stories_generate_with_test_token_returns_story():
    response = client.post(
        "/stories/generate",
        headers={
            "Authorization": "Bearer test:user-1",
            "X-Firebase-AppCheck": "test",
        },
        json={
            "kind": "story",
            "user": {"id": "user-1", "email": "parent@example.com"},
            "child": {
                "id": "child-1",
                "userId": "user-1",
                "firstName": "Lina",
                "preferredTone": "reassuring",
                "storyLengthMinutes": 10,
            },
            "chapterIndex": 1,
            "totalChapters": 7,
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["result"]["title"]
    assert body["result"]["content"]


def test_stripe_checkout_with_test_token_returns_url():
    response = client.post(
        "/stripe/checkout",
        headers={
            "Authorization": "Bearer test:user-1",
            "X-Firebase-AppCheck": "test",
        },
        json={"planId": "plan_elunai", "email": "parent@example.com"},
    )

    assert response.status_code == 200
    assert response.json()["url"].startswith("https://checkout.stripe.com/")


def test_stripe_checkout_rejects_unknown_plan():
    response = client.post(
        "/stripe/checkout",
        headers={
            "Authorization": "Bearer test:user-1",
            "X-Firebase-AppCheck": "test",
        },
        json={"planId": "plan_admin"},
    )

    assert response.status_code == 400


def test_stories_generate_validates_payload():
    response = client.post(
        "/stories/generate",
        headers={
            "Authorization": "Bearer test:user-1",
            "X-Firebase-AppCheck": "test",
        },
        json={"kind": "story"},
    )

    assert response.status_code == 422


def test_stories_generate_rejects_foreign_child_profile():
    response = client.post(
        "/stories/generate",
        headers={
            "Authorization": "Bearer test:user-1",
            "X-Firebase-AppCheck": "test",
        },
        json={
            "kind": "story",
            "user": {"id": "user-1"},
            "child": {"id": "child-1", "userId": "user-2"},
        },
    )

    assert response.status_code == 403


def test_stripe_webhook_mock_accepts_subscription_update(monkeypatch):
    writes = []

    class FakeDoc:
        def __init__(self, path):
            self.path = path

        def set(self, data, merge=False):
            writes.append((self.path, data, merge))

    class FakeCollection:
        def __init__(self, name):
            self.name = name

        def document(self, doc_id):
            return FakeDoc(f"{self.name}/{doc_id}")

    class FakeDb:
        def collection(self, name):
            return FakeCollection(name)

    monkeypatch.setattr("app.subscriptions.firestore_client", lambda: FakeDb())

    response = client.post(
        "/stripe/webhook",
        json={
            "type": "customer.subscription.updated",
            "data": {
                "object": {
                    "id": "sub_123",
                    "customer": "cus_123",
                    "status": "active",
                    "start_date": 1_700_000_000,
                    "current_period_end": 1_702_592_000,
                    "metadata": {
                        "firebaseUid": "user-1",
                        "planId": "plan_elunai",
                    },
                }
            },
        },
    )

    assert response.status_code == 200
    assert response.json()["handled"] == "customer.subscription.updated"
    assert writes[0][0] == "subscriptions/user-1"
    assert writes[0][1]["status"] == "active"
    assert writes[1][0] == "users/user-1"
    assert writes[1][1]["subscriptionStatus"] == "active"


def test_delete_account_deletes_user_scoped_data(monkeypatch):
    deletes = []

    class FakeRef:
        def __init__(self, path):
            self.path = path

        def delete(self):
            deletes.append(self.path)

        def set(self, data, merge=False):
            pass

    class FakeSnap:
        def __init__(self, path):
            self.reference = FakeRef(path)

    class FakeQuery:
        def __init__(self, collection_name):
            self.collection_name = collection_name

        def stream(self):
            return [FakeSnap(f"{self.collection_name}/doc-1")]

    class FakeCollection:
        def __init__(self, name):
            self.name = name

        def where(self, *_args):
            return FakeQuery(self.name)

        def document(self, doc_id):
            return FakeRef(f"{self.name}/{doc_id}")

    class FakeDb:
        def collection(self, name):
            return FakeCollection(name)

    class FakeAuth:
        def delete_user(self, uid):
            deletes.append(f"auth/{uid}")

    monkeypatch.setattr("app.account.firestore_client", lambda: FakeDb())
    monkeypatch.setattr("app.account._firebase_auth", lambda: FakeAuth())

    response = client.delete(
        "/account",
        headers={
            "Authorization": "Bearer test:user-1",
            "X-Firebase-AppCheck": "test",
        },
    )

    assert response.status_code == 200
    assert "auth/user-1" in deletes


def test_provision_admin_preserves_claims_and_activates_access(monkeypatch):
    writes = []
    claims = []

    class FakeMetadata:
        creation_timestamp = 1_700_000_000_000

    class FakeUser:
        uid = "admin-user"
        custom_claims = {"support": True}
        user_metadata = FakeMetadata()

    class FakeAuth:
        class UserNotFoundError(Exception):
            pass

        def get_user_by_email(self, email):
            assert email == "admin@example.com"
            return FakeUser()

        def set_custom_user_claims(self, uid, value):
            claims.append((uid, value))

    class FakeDoc:
        def __init__(self, path):
            self.path = path

        def set(self, data, merge=False):
            writes.append((self.path, data, merge))

    class FakeCollection:
        def __init__(self, name):
            self.name = name

        def document(self, doc_id):
            return FakeDoc(f"{self.name}/{doc_id}")

    class FakeDb:
        def collection(self, name):
            return FakeCollection(name)

    monkeypatch.setattr("scripts.provision_admin._firebase_auth", lambda: FakeAuth())
    monkeypatch.setattr("scripts.provision_admin.firestore_client", lambda: FakeDb())

    uid, created = provision_admin(" ADMIN@example.com ", create_if_missing=False)

    assert uid == "admin-user"
    assert created is False
    assert claims == [("admin-user", {"support": True, "admin": True})]
    assert writes[0][0] == "users/admin-user"
    assert writes[0][1]["isAdmin"] is True
    assert writes[1][0] == "subscriptions/admin-user"
    assert writes[1][1]["status"] == "active"
