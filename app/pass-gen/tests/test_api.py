import re

def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json().get("status") == "ok"

def test_generate_default(client):
    r = client.get("/generate")
    assert r.status_code == 200
    pwd = r.get_json().get("password")
    assert isinstance(pwd, str)
    assert 8 <= len(pwd) <= 128

def test_generate_length_bounds(client):
    # Too small
    r = client.get("/generate?length=4")
    assert r.status_code == 400
    # Too large
    r = client.get("/generate?length=999")
    assert r.status_code == 400
    # Valid explicit
    r = client.get("/generate?length=12")
    assert r.status_code == 200
    assert len(r.get_json()["password"]) == 12

def test_generate_charset_flags(client):
    # No uppercase, no digits, no symbols => only lowercase letters
    r = client.get("/generate?length=32&digits=false&symbols=false&uppercase=false")
    assert r.status_code == 200
    pwd = r.get_json()["password"]
    assert len(pwd) == 32
    assert re.fullmatch(r"[a-z]+", pwd), f"Unexpected chars: {pwd}"

    # Uppercase only (no digits/symbols)
    r = client.get("/generate?length=20&digits=false&symbols=false&uppercase=true")
    assert r.status_code == 200
    pwd2 = r.get_json()["password"]
    assert re.fullmatch(r"[a-zA-Z]+", pwd2)

def test_passwords_crud(client):
    # Initially empty
    r0 = client.get("/passwords")
    assert r0.status_code == 200
    assert isinstance(r0.get_json(), list)
    n0 = len(r0.get_json())

    # Save one
    payload = {"name": "github", "password": "abcDEF123!"}
    r1 = client.post("/passwords", json=payload)
    assert r1.status_code == 200
    assert r1.get_json().get("status") == "saved"

    # List again
    r2 = client.get("/passwords")
    assert r2.status_code == 200
    items = r2.get_json()
    assert len(items) == n0 + 1
    last = items[0]
    assert last["name"] == "github"
    assert "password" in last  # current API returns it; we rely on frontend fix to not expose in UI

    # Delete
    r3 = client.delete(f"/passwords/{last['id']}")
    assert r3.status_code == 200
    assert r3.get_json().get("status") == "deleted"

    # List is back to original size
    r4 = client.get("/passwords")
    assert len(r4.get_json()) == n0
