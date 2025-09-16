from flask import Flask, request, jsonify
from flask_cors import CORS
import secrets
import string

app = Flask(__name__)
CORS(app)

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
    """Strict boolean parser with default fallback."""
    if val is None:
        return default
    v = str(val).strip().lower()
    if v in ("1", "true", "t", "yes", "y", "on"):
        return True
    if v in ("0", "false", "f", "no", "n", "off"):
        return False
    return None

@app.get("/generate")
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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
