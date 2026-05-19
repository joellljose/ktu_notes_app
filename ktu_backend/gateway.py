import requests
from flask import Flask, request, Response
from flask_cors import CORS

app = Flask(__name__)
app.url_map.strict_slashes = False # Allow both /path and /path/
CORS(app)

# --- Configuration ---
BACKENDS = {
    'gemini': 'http://localhost:5000',
    'gemma': 'http://localhost:5001',
    'moderation': 'http://localhost:5002',
    'ollama': 'http://localhost:11434'
}

@app.route('/<backend>/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
@app.route('/<backend>/', defaults={'path': ''}, methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
def proxy(backend, path):
    """
    Proxies requests from the gateway to the appropriate backend service.
    """
    if backend not in BACKENDS:
        return f"Unknown backend: {backend}", 404

    target_url = f"{BACKENDS[backend]}/{path}"
    print(f"Proxying request: {request.method} {request.url} -> {target_url}")

    try:
        # Forward the request to the target backend
        resp = requests.request(
            method=request.method,
            url=target_url,
            headers={key: value for (key, value) in request.headers if key != 'Host'},
            data=request.get_data(),
            cookies=request.cookies,
            allow_redirects=True, # Follow internal redirects (e.g. slash fixes)
            params=request.args,
            timeout=300 # Wait for LLM to respond
        )

        # Build the response to return to the client
        excluded_headers = ['content-encoding', 'content-length', 'transfer-encoding', 'connection']
        headers = [(name, value) for (name, value) in resp.raw.headers.items()
                   if name.lower() not in excluded_headers]

        response = Response(resp.content, resp.status_code, headers)
        return response

    except requests.exceptions.ConnectionError:
        return f"Error: Could not connect to {backend} backend at {BACKENDS[backend]}. Is it running?", 502
    except Exception as e:
        return f"Gateway Error: {str(e)}", 500

@app.route('/')
def health_check():
    return {
        "status": "Gateway Online",
        "backends": BACKENDS,
        "usage": "Use /gemini/, /gemma/, or /moderation/ as prefixes."
    }

if __name__ == '__main__':
    print("Starting Unified API Gateway on port 8000...")
    print("Make sure to run 'ngrok http 8000'")
    app.run(host='0.0.0.0', port=8000, debug=False)
