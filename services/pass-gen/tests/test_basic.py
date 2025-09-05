import json
from app import app

def test_generate_default():
    client = app.test_client()
    resp = client.get("/generate?length=12")
    assert resp.status_code == 200
    data = resp.get_json()
    assert "password" in data and isinstance(data["password"], str)
    assert len(data["password"]) == 12
