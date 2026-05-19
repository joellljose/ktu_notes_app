import requests
import json

try:
    req = requests.post(
        'http://127.0.0.1:5000/generate-diagram',
        json={'topic': 'architecture of CPU'}
    )
    if req.status_code == 200:
        data = req.json()
        print("----- MERMAID RAW -----")
        print(repr(data.get('mermaid_code')))
    else:
        print(f"Error {req.status_code}: {req.text}")
except Exception as e:
    print(f"Could not connect to local server: {e}")
