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

def to_bool(val, default=True):
    if val is None: return default
    v = str(val).strip().lower()
    return v in ("1", "true", "t", "yes", "y", "on")

@app.get("/generate")
def generate():
    try:
        length = int(request.args.get("length", 16))
        if length < 1 or length > 256:
            return jsonify(error="length must be between 1 and 256"), 400
    except ValueError:
        return jsonify(error="length must be an integer"), 400

    include_digits   = to_bool(request.args.get("digits"),   True)
    include_symbols  = to_bool(request.args.get("symbols"),  True)
    include_upper    = to_bool(request.args.get("uppercase"), True)

    charset = build_charset(include_digits, include_symbols, include_upper)
    if not charset:
        return jsonify(error="character set is empty"), 400

    password = ''.join(secrets.choice(charset) for _ in range(length))
    return jsonify(password=password)

@app.get("/health")
def health():
    return jsonify(status="ok")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
