import requests
import json

url = "https://leonor-unsoporific-admiratively.ngrok-free.dev/smart-search"
payload = {
    "query": "TCP Handshake",
    "branch": "Computer Science",
    "semester": "S5"
}
headers = {
    'Content-Type': 'application/json'
}

try:
    response = requests.post(url, headers=headers, data=json.dumps(payload), timeout=30)
    print(f"Status Code: {response.status_code}")
    print("Response Content:")
    print(response.text)
except Exception as e:
    print(f"Request failed: {e}")
