# tests/test_routes.py

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health_check/")
    assert response.status_code == 200
    json_response = response.json()
    assert json_response["status"] in ["success", "error"]


def test_execute_query_endpoint():
    payload = {"query": "SELECT 1 AS Test"}
    response = client.post("/execute_query/", json=payload)
    assert response.status_code == 200
    assert "results" in response.json()
