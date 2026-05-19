import requests
import json

def test_creative_hint():
    url = "http://localhost:5000/generate-creative-hint"
    payload = {
        "topic": "Dijkstra's Algorithm",
        "subject": "Data Structures",
        "branch": "Computer Science",
        "semester": "S3"
    }
    headers = {'Content-Type': 'application/json'}

    try:
        response = requests.post(url, data=json.dumps(payload), headers=headers)
        if response.status_code == 200:
            print("Success!")
            print(json.dumps(response.json(), indent=2))
        else:
            print(f"Failed with status: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"Error connecting to backend: {e}")

if __name__ == "__main__":
    # Note: Requires the Flask server to be running on localhost:5000
    test_creative_hint()
