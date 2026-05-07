from fastapi.testclient import TestClient
import pytest

from inference.app_factory import create_app
from inference.config import API_KEY

@pytest.fixture
def client():
    # Force use of DummyModel for testing
    import os
    os.environ["MODEL_NAME"] = "dummy"
    return TestClient(create_app())


def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "ok"


def test_generate_image(client):
    res = client.post(
        "/generate",
        headers={"Authorization": f"Bearer {API_KEY}"},
        json={"prompt": "A beautiful just intonation visualization"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["type"] == "image"
    assert "payload" in data
    assert data["metadata"]["prompt"] == "A beautiful just intonation visualization"


def test_auth_failure(client):
    res = client.post(
        "/generate",
        headers={"Authorization": "Bearer WRONG-KEY"},
        json={"prompt": "test"},
    )
    assert res.status_code == 403
