import requests
import json

URL = 'https://api-gemini-notes-production.up.railway.app/smart-search'

payload = {
    'query': 'Computer Science',
    'branch': 'Computer Science',
    'semester': 'S1'
}

print(f"Testing {URL} with payload: {payload}")

try:
    response = requests.post(URL, json=payload, timeout=30)
    print(f"Status Code: {response.status_code}")
    print("Response Body:")
    try:
        print(json.dumps(response.json(), indent=2))
    except:
        print(response.text)
except Exception as e:
    print(f"Error connecting: {e}")
