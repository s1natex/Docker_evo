from flask import Flask, request, jsonify
from flask_cors import CORS
import secrets, string, psycopg2, os
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
CORS(app)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1)

limiter = Limiter(key_func=get_remote_address, app=app, default_limits=["60 per minute"])

DATABASE_URL = os.getenv("DATABASE_URL")

def get_conn():
    return psycopg2.connect(DATABASE_URL)

with get_conn() as conn, conn.cursor() as cur:
    cur.execute(open("db_init.sql").read())
    conn.commit()

@app.get("/generate")
@limiter.limit("10 per second")
@limiter.limit("100 per minute")
def generate():
    try:
        length = int(request.args.get("length", 16))
    except ValueError:
        return jsonify(error="length must be integer"), 400
    if length < 8 or length > 128:
        return jsonify(error="length must be between 8 and 128"), 400

    digits = request.args.get("digits", "true").lower() in ("true", "1", "yes", "y")
    symbols = request.args.get("symbols", "true").lower() in ("true", "1", "yes", "y")
    uppercase = request.args.get("uppercase", "true").lower() in ("true", "1", "yes", "y")

    chars = list(string.ascii_lowercase)
    if uppercase: chars += list(string.ascii_uppercase)
    if digits: chars += list(string.digits)
    if symbols: chars += list(string.punctuation)

    password = ''.join(secrets.choice(chars) for _ in range(length))
    return jsonify(password=password)

@app.get("/passwords")
def get_passwords():
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, name, password, created_at FROM saved_passwords ORDER BY created_at DESC")
        rows = cur.fetchall()
    return jsonify([{"id": r[0], "name": r[1], "password": r[2], "created_at": r[3]} for r in rows])

@app.post("/passwords")
def save_password():
    data = request.get_json()
    name = data.get("name")
    password = data.get("password")
    if not name or not password:
        return jsonify(error="name and password required"), 400
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO saved_passwords (name, password) VALUES (%s, %s)", (name, password))
        conn.commit()
    return jsonify(status="saved")

@app.delete("/passwords/<int:id>")
def delete_password(id):
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("DELETE FROM saved_passwords WHERE id=%s", (id,))
        conn.commit()
    return jsonify(status="deleted")

@app.get("/health")
def health():
    return jsonify(status="ok")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
