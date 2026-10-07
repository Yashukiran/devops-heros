from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_root():
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["service"] == "task-tracker-api"


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_create_and_list_tasks():
    r = client.post("/api/tasks", json={"title": "Write tests"})
    assert r.status_code == 201
    task = r.json()
    assert task["title"] == "Write tests" and task["done"] is False
    assert any(t["id"] == task["id"] for t in client.get("/api/tasks").json())


def test_complete_task():
    task_id = client.post("/api/tasks", json={"title": "Finish me"}).json()["id"]
    r = client.patch(f"/api/tasks/{task_id}")
    assert r.status_code == 200 and r.json()["done"] is True


def test_validation_and_not_found():
    assert client.post("/api/tasks", json={"title": ""}).status_code == 422
    assert client.patch("/api/tasks/99999").status_code == 404


def test_metrics_exposed():
    client.get("/health")
    r = client.get("/metrics")
    assert r.status_code == 200
    assert 'http_requests_total{method="GET",path="/health",status="200"}' in r.text
    assert "tasks_total" in r.text
