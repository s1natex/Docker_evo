import string

def get_json(client, path):
    r = client.get(path)
    return r.status_code, r.get_json()

def test_generate_default(client):
    code, data = get_json(client, "/generate")
    assert code == 200
    assert "password" in data and isinstance(data["password"], str)
    assert 8 <= len(data["password"]) <= 128

def test_length_bounds_ok(client):
    code8, data8 = get_json(client, "/generate?length=8")
    assert code8 == 200 and len(data8["password"]) == 8
    code128, data128 = get_json(client, "/generate?length=128")
    assert code128 == 200 and len(data128["password"]) == 128

def test_length_too_small(client):
    code, data = get_json(client, "/generate?length=7")
    assert code == 400
    assert "error" in data

def test_length_too_large(client):
    code, data = get_json(client, "/generate?length=129")
    assert code == 400
    assert "error" in data

def test_length_not_int(client):
    code, data = get_json(client, "/generate?length=abc")
    assert code == 400
    assert "error" in data

def test_invalid_boolean_rejected(client):
    code, data = get_json(client, "/generate?digits=maybe")
    assert code == 400
    assert "error" in data

def test_disallow_digits(client):
    code, data = get_json(client, "/generate?length=20&digits=false&symbols=true&uppercase=true")
    assert code == 200
    pw = data["password"]
    assert all(ch not in string.digits for ch in pw)

def test_disallow_symbols(client):
    code, data = get_json(client, "/generate?length=20&symbols=false&digits=true&uppercase=true")
    assert code == 200
    pw = data["password"]
    assert all(ch not in string.punctuation for ch in pw)

def test_disallow_uppercase(client):
    code, data = get_json(client, "/generate?length=20&uppercase=false&digits=true&symbols=true")
    assert code == 200
    pw = data["password"]
    assert all(ch not in string.ascii_uppercase for ch in pw)
