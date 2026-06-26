import pytest
from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        yield client


def test_home_returns_200(client):
    response = client.get("/")
    assert response.status_code == 200


def test_home_returns_correct_json(client):
    response = client.get("/")
    data = response.get_json()
    assert data["status"] == "ok"
    assert data["service"] == "FinCorp API"


def test_health_returns_200(client):
    response = client.get("/health")
    assert response.status_code == 200


def test_health_is_healthy(client):
    response = client.get("/health")
    data = response.get_json()
    assert data["healthy"] is True


def test_invalid_route_returns_404(client):
    response = client.get("/nonexistent")
    assert response.status_code == 404
