import os
import sys
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
os.environ["GENERATION_RATE_LIMIT_PER_HOUR"] = "0"

from app.main import app  # noqa: E402
from app.rate_limit import check_generation_rate_limit  # noqa: E402
from app.story_generation import _mock_story, _normalize_story, _story_prompt  # noqa: E402


client = TestClient(app)


def test_local_fallback_is_long_enough_for_mobile_validation():
    story = _mock_story(
        {
            "ageYears": 8,
            "child": {"firstName": "Lina", "storyLengthMinutes": 10},
        }
    )

    assert story["generationSource"] == "backend-fallback"
    assert 800 <= len(story["content"].split()) <= 1200


def test_story_prompt_includes_minimum_length():
    prompt = _story_prompt(
        {
            "ageYears": 8,
            "child": {"firstName": "Lina", "storyLengthMinutes": 10},
        }
    )

    assert "entre 800 et 1200 mots" in prompt
    assert "environ 1000 mots" in prompt
    assert "10 à 12 paragraphes" in prompt


@pytest.mark.parametrize("word_count", [799, 1201])
def test_story_normalization_rejects_duration_outside_8_to_12_minutes(word_count):
    with pytest.raises(ValueError):
        _normalize_story(
            {"content": "mot " * word_count},
            {"child": {"storyLengthMinutes": 10}},
        )


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
