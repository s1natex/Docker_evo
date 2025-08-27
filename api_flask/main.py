from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/get', methods=['GET'])
def hello():
    return jsonify(message="Hello, World!")

@app.route('/post', methods=['POST'])
def echo():
    data = request.json
    return jsonify(data)

@app.errorhandler(404)
def not_found(error):
    return jsonify(error="Not Found"), 404

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)