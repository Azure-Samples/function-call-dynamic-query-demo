from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_execute_query():
    response = client.post("/execute_query/", json={"query": "SELECT TOP 1 * FROM Person"})
    assert response.status_code == 200
    assert "results" in response.json()

def test_ask_gpt():
    response = client.post("/ask_gpt/", json={"user_query": "What are the total sales for the last month?"})
    assert response.status_code == 200
    assert "results" in response.json()

def test_health_check():
    response = client.get("/health_check/")
    assert response.status_code == 200
    assert response.json()["status"] == "success"
