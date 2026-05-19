import requests
import json

def test_moderation(message):
    url = "http://localhost:5002/moderate-message"
    payload = {"message": message}
    headers = {'Content-Type': 'application/json'}
    
    print(f"\nChecking: '{message}'")
    try:
        response = requests.post(url, data=json.dumps(payload), headers=headers)
        if response.status_code == 200:
            print("Response:", json.dumps(response.json(), indent=2))
        else:
            print("Failed:", response.status_code, response.text)
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    # Test cases
    test_moderation("How to solve BFS in Python?")
    test_moderation("How is your home? Hope everything is fine.")
    test_moderation("What is the syllabus for Module 2 of Data Structures?")
    test_moderation("Do you want to go for a movie tonight?")
