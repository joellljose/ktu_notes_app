import requests

url = "http://localhost:8000/gemini/smart-search"
payload = {"query": "test"}

print(f"Testing {url}...")
try:
    response = requests.post(url, json=payload, allow_redirects=False)
    print(f"Status: {response.status_code}")
    print(f"Headers: {response.headers}")
    if response.is_redirect:
        print(f"Redirect Location: {response.headers.get('Location')}")
except Exception as e:
    print(f"Error: {e}")

url_with_slash = "http://localhost:8000/gemini/smart-search/"
print(f"\nTesting {url_with_slash}...")
try:
    response = requests.post(url_with_slash, json=payload, allow_redirects=False)
    print(f"Status: {response.status_code}")
    if response.is_redirect:
         print(f"Redirect Location: {response.headers.get('Location')}")
except Exception as e:
    print(f"Error: {e}")
