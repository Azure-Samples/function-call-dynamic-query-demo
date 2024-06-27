# tests/test_main.py

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Establishing Root Endpoint"}


def test_ask_endpoint():
    payload = {"message": "How many products with the color red do we have?"}
    response = client.post("/ask/", json=payload)
    assert response.status_code == 200
    # Check if the response contains expected keys
    assert "response" in response.json() or "error" in response.json()
