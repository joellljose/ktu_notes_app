import os
import requests
from dotenv import load_dotenv
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
ENV_PATH = BASE_DIR / '.env'
load_dotenv(dotenv_path=ENV_PATH)

ollama_url = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434")
ollama_model = os.environ.get("OLLAMA_MODEL", "gemma:7b")

print(f"Ollama URL: {ollama_url}")
print(f"Ollama Model: {ollama_model}")

try:
    response = requests.get(f"{ollama_url}/api/tags", timeout=5)
    if response.status_code == 200:
        models = [m['name'] for m in response.json().get('models', [])]
        print(f"Available models: {models}")
        if ollama_model in models or f"{ollama_model}:latest" in models:
            print(f"SUCCESS: Model {ollama_model} is available.")
        else:
            print(f"ERROR: Model {ollama_model} is NOT pulled. Available models: {models}")
    else:
        print(f"ERROR: Ollama returned status {response.status_code}")
except Exception as e:
    print(f"ERROR: Could not connect to Ollama at {ollama_url}. Is it running? ({e})")
