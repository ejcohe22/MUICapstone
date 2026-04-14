from fastapi.testclient import TestClient

from inference.app_factory import create_app
from inference.config import API_KEY

client = TestClient(create_app())


def test_generate():
    res = client.post(
        "/generate",
        headers={"Authorization": f"Bearer {API_KEY}"},
        json={"prompt": "test"},
    )
    assert res.status_code == 200
