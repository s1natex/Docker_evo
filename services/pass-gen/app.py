from flask import Flask, request, jsonify
from flask_cors import CORS
import secrets
import string
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
CORS(app)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1)

limiter = Limiter(
    key_func=get_remote_address,
    app=app,
    default_limits=["60 per minute"],
)

def build_charset(include_digits=True, include_symbols=True, include_uppercase=True):
    chars = list(string.ascii_lowercase)
    if include_uppercase:
        chars += list(string.ascii_uppercase)
    if include_digits:
        chars += list(string.digits)
    if include_symbols:
        chars += list(string.punctuation)
    return ''.join(chars)

def parse_bool(val, default=True):
    if val is None:
        return default
    v = str(val).strip().lower()
    if v in ("1", "true", "t", "yes", "y", "on"):
        return True
    if v in ("0", "false", "f", "no", "n", "off"):
        return False
    return None

@app.get("/generate")
@limiter.limit("10 per second")
@limiter.limit("100 per minute")
def generate():
    try:
        length = int(request.args.get("length", 16))
    except ValueError:
        return jsonify(error="length must be an integer"), 400
    if length < 8 or length > 128:
        return jsonify(error="length must be between 8 and 128"), 400

    digits = parse_bool(request.args.get("digits"), True)
    symbols = parse_bool(request.args.get("symbols"), True)
    uppercase = parse_bool(request.args.get("uppercase"), True)
    if digits is None or symbols is None or uppercase is None:
        return jsonify(error="digits, symbols, uppercase must be boolean (true/false)"), 400

    charset = build_charset(digits, symbols, uppercase)
    if not charset:
        return jsonify(error="character set is empty"), 400

    password = ''.join(secrets.choice(charset) for _ in range(length))
    return jsonify(password=password)

@app.get("/health")
def health():
    return jsonify(status="ok")

@limiter.request_filter
def _health_free():
    return request.path == "/health"

@app.errorhandler(429)
def _ratelimit_handler(e):
    return jsonify(error="rate limit exceeded", detail=str(e.description)), 429

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
