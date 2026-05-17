import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

os.environ["ALLOW_TEST_BEARER_TOKEN"] = "true"
os.environ["OPENAI_MOCK"] = "true"
os.environ["STRIPE_MOCK"] = "true"
os.environ["FIRESTORE_EMULATOR_HOST"] = "localhost:8080"

from app.main import app  # noqa: E402


client = TestClient(app)


def test_stories_generate_requires_firebase_token():
    response = client.post("/stories/generate", json={})

    assert response.status_code == 401


def test_stories_generate_with_test_token_returns_story():
    response = client.post(
        "/stories/generate",
        headers={"Authorization": "Bearer test:user-1"},
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
        headers={"Authorization": "Bearer test:user-1"},
        json={"planId": "plan_elunai", "email": "parent@example.com"},
    )

    assert response.status_code == 200
    assert response.json()["url"].startswith("https://checkout.stripe.com/")


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
