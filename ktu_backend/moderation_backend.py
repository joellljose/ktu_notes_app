import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import re
import os
from pathlib import Path
from dotenv import load_dotenv

app = Flask(__name__)
CORS(app)

# Robust Path Handling
BASE_DIR = Path(__file__).resolve().parent
ENV_PATH = BASE_DIR / '.env'
load_dotenv(dotenv_path=ENV_PATH)

# --- Ollama Configuration ---
OLLAMA_BASE_URL = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "gemma:2b")

@app.route('/')
def health_check():
    return "Moderation Backend is Running!"

def call_ollama(prompt):
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
        "format": "json"
    }
    try:
        response = requests.post(f"{OLLAMA_BASE_URL}/api/generate", json=payload, timeout=60)
        if response.status_code == 200:
            return response.json().get("response", "")
        else:
            return f"ERROR: Status {response.status_code}"
    except Exception as e:
        return f"ERROR: {str(e)}"

@app.route('/moderate-message', methods=['POST'])
def moderate_message():
    print(">>> Received request for moderation...")
    try:
        data = request.get_json()
        message = data.get('message', '').strip()
        history = data.get('history', []) # List of strings: last 5-10 messages
        
        if not message:
            return jsonify({"is_academic": True, "warning_reason": ""})

        history_context = "\n".join([f"- {msg}" for msg in history[-10:]]) # Limit to last 10

        prompt = f"""
        Act as a strict academic moderator for a university study group. 
        
        RECENT CHAT HISTORY:
        {history_context if history_context else "No recent messages."}
        
        NEW MESSAGE TO EVALUATE: "{message}"
        
        RULES:
        1. Academic messages include: KTU exam dates, engineering doubts, subject syllabus, university events, or study tips.
        2. "Meta-Academic" messages ARE ALLOWED if they follow academic context. For example, "I'll eat and come back to explain" is ALLOWED if the history shows people are discussing studies. "Thanks", "BRB", "Wait" are also ALLOWED in an academic context.
        3. Forbidden messages (Strictly Prohibited): Conversations about personal health ("how are you"), social talk ("what's for dinner", "movie"), gaming, or casual non-study chat that DOES NOT follow a study session.
        4. Be strict but fair. If the group is discussing studies, allow meta-talk about study breaks.
        
        Return ONLY valid JSON in this format:
        {{
            "is_academic": true or false,
            "warning_reason": "Provide a 1-sentence explanation if false, otherwise empty"
        }}
        """

        response_text = call_ollama(prompt)
        # Clean response text in case there's extra text
        clean_json = re.sub(r'```json|```', '', response_text).strip()
        ai_data = json.loads(clean_json)
        
        # Debugging: Print analyzed result
        print(f"\n--- AI Analysis ---")
        print(f"Message: {message}")
        print(f"Result: {ai_data}")
        print(f"-------------------\n")
        
        return jsonify({
            "is_academic": ai_data.get('is_academic', True),
            "warning_reason": ai_data.get('warning_reason', "Please keep discussions academic.")
        })

    except Exception as e:
        # Fallback to permissive in case of server error
        print(f"Moderation Error: {e}")
        return jsonify({"is_academic": True, "warning_reason": ""})

if __name__ == '__main__':
    # Running on port 5002 for moderation specifically
    print(f"Starting Moderation Backend with model: {OLLAMA_MODEL}")
    app.run(host='0.0.0.0', port=5002, debug=True)
