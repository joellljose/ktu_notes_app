import requests
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import json
import re
import fitz  
import os
import io
import firebase_admin
from firebase_admin import credentials, firestore, messaging
from pathlib import Path
from dotenv import load_dotenv
import time
import traceback
from functools import wraps

app = Flask(__name__, static_folder='static')
CORS(app)

# Robust Path Handling
BASE_DIR = Path(__file__).resolve().parent
ENV_PATH = BASE_DIR / '.env'
CREDS_PATH = BASE_DIR / 'serviceAccountKey.json'

load_dotenv(dotenv_path=ENV_PATH)
print(f"Loading .env from: {ENV_PATH}")

# Ensure upload directory exists
UPLOAD_FOLDER = BASE_DIR / 'static' / 'notes'
UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)

# --- Firebase Init ---
try:
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(CREDS_PATH))
        firebase_admin.initialize_app(cred)
    print("Firebase Admin Initialized")
except Exception as e:
    print(f"Warning: Firebase Admin not initialized: {e}")

# --- Ollama Configuration ---
OLLAMA_BASE_URL = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "gemma:7b")

class OllamaResponse:
    def __init__(self, text):
        self.text = text

class OllamaChatSession:
    def __init__(self, model_name, history=None):
        self.model_name = model_name
        self.history = history or []

    def send_message(self, message):
        # Ensure the first message is from the 'user'
        processed_history = []
        for h in self.history:
            role = "user" if h.get("role") == "user" else "assistant"
            content = h.get("text", "") 
            if not content and "parts" in h:
                content = h["parts"][0] if isinstance(h["parts"], list) else h["parts"]
            processed_history.append({"role": role, "content": content})
            
        while processed_history and processed_history[0]["role"] != "user":
            processed_history.pop(0)

        # Build messages with a possible system message first
        messages = []
        # If the message starts with "SYSTEM_INSTRUCTION:", extract it
        if message.startswith("SYSTEM_INSTRUCTION:"):
            parts = message.split("\n\nQuestion: ", 1)
            if len(parts) == 2:
                system_text = parts[0].replace("SYSTEM_INSTRUCTION:", "").strip()
                messages.append({"role": "system", "content": system_text})
                message = parts[1]

        messages.extend(processed_history)
        messages.append({"role": "user", "content": message})
        
        payload = {
            "model": self.model_name,
            "messages": messages,
            "stream": False
        }
        
        try:
            response = requests.post(f"{OLLAMA_BASE_URL}/api/chat", json=payload, timeout=300)
            if response.status_code != 200:
                error_msg = f"Ollama Error {response.status_code}: {response.text}"
                print(error_msg)
                return OllamaResponse(f"ERROR: {error_msg}")
            
            data = response.json()
            content = data.get("message", {}).get("content", "")
            return OllamaResponse(content)
        except requests.exceptions.ConnectionError:
            msg = f"ERROR: Could not connect to Ollama at {OLLAMA_BASE_URL}. Is it running?"
            print(msg)
            return OllamaResponse(msg)
        except Exception as e:
            print(f"Ollama Chat Error: {e}")
            return OllamaResponse(f"ERROR: {str(e)}")

class OllamaModel:
    def __init__(self, model_name):
        self.model_name = model_name

    def generate_content(self, prompt):
        payload = {
            "model": self.model_name,
            "prompt": prompt,
            "stream": False
        }
        try:
            response = requests.post(f"{OLLAMA_BASE_URL}/api/generate", json=payload, timeout=300)
            if response.status_code != 200:
                error_msg = f"Ollama Error {response.status_code}: {response.text}"
                print(error_msg)
                return OllamaResponse(f"ERROR: {error_msg}")
                
            data = response.json()
            return OllamaResponse(data.get("response", ""))
        except requests.exceptions.ConnectionError:
            msg = f"ERROR: Could not connect to Ollama at {OLLAMA_BASE_URL}. Is it running?"
            print(msg)
            return OllamaResponse(msg)
        except Exception as e:
            print(f"Ollama Generate Error: {e}")
            return OllamaResponse(f"ERROR: {str(e)}")

    def start_chat(self, history=None):
        return OllamaChatSession(self.model_name, history)

def get_configured_model():
    return OllamaModel(OLLAMA_MODEL)

# --- Cloudinary Init ---
import cloudinary
import cloudinary.uploader

CLOUDINARY_CLOUD_NAME = os.environ.get("CLOUDINARY_CLOUD_NAME")
CLOUDINARY_API_KEY = os.environ.get("CLOUDINARY_API_KEY")
CLOUDINARY_API_SECRET = os.environ.get("CLOUDINARY_API_SECRET")

if CLOUDINARY_CLOUD_NAME:
    cloudinary.config( 
        cloud_name = CLOUDINARY_CLOUD_NAME, 
        api_key = CLOUDINARY_API_KEY, 
        api_secret = CLOUDINARY_API_SECRET,
        secure = True
    )
    print("Cloudinary Configured")

def upload_to_cloudinary(file_obj, filename):
    try:
        clean_filename = "".join([c if c.isalnum() or c in "._-" else "_" for c in filename])
        res_type = "raw" if filename.lower().endswith(".pdf") else "auto"
        response = cloudinary.uploader.upload(
            file_obj, 
            resource_type = res_type,
            folder = "ktu_notes",
            public_id = clean_filename.split('.')[0] 
        )
        return response.get("secure_url"), response.get("public_id")
    except Exception as e:
        print(f"Cloudinary Upload Error: {e}")
        raise e

def extract_text_from_pdf_stream(file_stream):
    try:
        with fitz.open(stream=file_stream.read(), filetype="pdf") as doc:
            text = ""
            for page in doc:
                text += page.get_text()
        file_stream.seek(0)
        return text
    except Exception as e:
        print(f"PDF Extract Error: {e}")
        return ""

@app.route('/verify-note', methods=['POST'])
def verify_note():
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file part"}), 400
        
        file = request.files['file']
        subject = request.form.get('subject', 'Unknown Subject')
        module = request.form.get('module', 'Unknown Module')
        
        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400

        filename = file.filename
        temp_path = UPLOAD_FOLDER / filename
        file.save(str(temp_path))

        ai_enabled = True
        try:
            db = firestore.client()
            settings_ref = db.collection('config').document('settings')
            doc = settings_ref.get()
            if doc.exists:
                ai_enabled = doc.to_dict().get('enableAiVerification', True)
        except Exception as db_e:
            print(f"Error fetching settings: {db_e}. Defaulting to AI ON.")

        extracted_text = ""
        status = "pending"
        reason = "AI Verification Failed or Skipped"
        ai_summary = "No summary generated."

        if not ai_enabled:
             status = "pending"
             reason = "Manual Mode Active (AI Verification Disabled)"
             ai_summary = "Pending Admin Review"
        else:
            try:
                with fitz.open(temp_path) as doc:
                    for page in doc:
                        extracted_text += page.get_text()
                
                if extracted_text.strip():
                    model = get_configured_model()
                    prompt = f"""
                    Act as a Syllabus Validator for KTU Engineering Course.
                    Subject: {subject}
                    Module: {module}
                    
                    Content of the Note:
                    {extracted_text[:10000]}
                    
                    Task:
                    1. Verify if the content is relevant to the Subject and Module provided.
                    2. If relevant, status is "approved". If completely irrelevant (spam, wrong subject), status is "rejected". If unsure or partially correct, status is "pending".
                    3. Generate a short 2-sentence summary of the note.
                    
                    CRITICAL: Return ONLY JSON. No other text.
                    {{
                        "status": "approved" | "rejected" | "pending",
                        "reason": "Explanation...",
                        "summary": "Short summary..."
                    }}
                    """
                    
                    response = model.generate_content(prompt)
                    clean_json = re.sub(r'```json|```', '', response.text).strip()
                    ai_data = json.loads(clean_json)
                    status = ai_data.get('status', 'pending')
                    reason = ai_data.get('reason', 'AI Review')
                    ai_summary = ai_data.get('summary', 'Summary not found')
            except Exception as e:
                print(f"Extraction/AI Error: {e}")
                status = "pending"
                reason = f"Error during processing: {str(e)}"

        file_url, file_path_id = upload_to_cloudinary(str(temp_path), filename)
        
        if temp_path.exists():
            os.remove(temp_path)

        return jsonify({
            "status": status,
            "reason": reason,
            "summary": ai_summary,
            "url": file_url,
            "fileId": file_path_id
        })
    except Exception as e:
        print(f"Verify Note Error: {e}")
        return jsonify({"error": str(e)}), 500

def extract_text_from_url(url):
    headers = {'User-Agent': 'Mozilla/5.0'}
    try:
        response = requests.get(url, headers=headers, timeout=20)
        if response.status_code == 200:
            with fitz.open(stream=response.content, filetype="pdf") as doc:
                text = "".join([page.get_text() for page in doc])
            return text
        else:
            raise Exception(f"Download failed: {response.status_code}")
    except Exception as e:
        raise Exception(f"Failed to extract text: {str(e)}")

@app.route('/generate-quiz', methods=['POST'])
def generate_quiz():
    try:
        data = request.get_json()
        input_text = data.get('text', '')
        pdf_url = data.get('url', '')
        source_text = input_text if input_text.strip() else extract_text_from_url(pdf_url)
        
        if not source_text.strip():
             return jsonify({"error": "No content found"}), 400
        
        model = get_configured_model()
        prompt = f"""
        Act as a University Professor. Generate 5 Multiple Choice Questions (MCQs) based on the text.
        Return ONLY a JSON array of objects. No intro/outro.
        [
            {{"question": "...", "options": ["...", "...", "...", "..."], "correctIndex": 0}}
        ]
        Text: {source_text[:12000]}
        """

        response = model.generate_content(prompt)
        clean_json = re.sub(r'```json|```', '', response.text).strip()
        quiz_data = json.loads(clean_json)
        
        try:
            db = firestore.client()
            db.collection('stats').document('quiz_generation').set({'count': firestore.Increment(1)}, merge=True)
        except: pass
        
        return jsonify(quiz_data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/generate-summary', methods=['POST'])
def generate_summary():
    try:
        data = request.get_json()
        pdf_url = data.get('url', '')
        length = data.get('length', 'medium')
        subject = data.get('subject', 'General Study Material')
        
        source_text = extract_text_from_url(pdf_url)
        
        format_instruction = {
            'short': "3-4 concise bullet points.",
            'detailed': "Comprehensive summary with definitions and multiple headings.",
            'medium': "6-8 clear descriptive bullet points."
        }.get(length, "6-8 bullet points.")
        
        model = get_configured_model()
        prompt = f"""
        Act as a KTU Professor. Summarize the text.
        Format: {format_instruction}
        Rules: Start directly with summary. No greetings.
        Text: {source_text[:15000]}
        """
        response = model.generate_content(prompt)
        return jsonify({"summary": response.text.strip()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/generate-topic-points', methods=['POST'])
def generate_topic_points():
    try:
        data = request.get_json()
        topic = data.get('topic', '').strip()
        subject = data.get('subject', '')
        
        model = get_configured_model()
        prompt = f"""
        Act as KTU Professor. Topic: "{topic}" ({subject}).
        Provide 5-7 concise high-value markdown bullet points. No intro.
        """
        response = model.generate_content(prompt)
        return jsonify({"points_markdown": response.text.strip()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/smart-search', methods=['POST'])
def smart_search():
    try:
        data = request.get_json()
        query = data.get('query', '').strip()
        branch = data.get('branch', '')
        semester = data.get('semester', '')
        subject = data.get('subject', '')
        
        found_notes = []
        try:
             db = firestore.client()
             notes_ref = db.collection('notes')
             base_query = notes_ref.where('status', '==', 'approved')
             if semester and semester != "Not Set":
                 base_query = base_query.where('semester', '==', semester)
             if branch and branch != "Not Set":
                  base_query = base_query.where('branch', '==', branch)
                  
             docs = base_query.stream()
             for doc in docs:
                 n = doc.to_dict()
                 found_notes.append({
                     "id": doc.id, "subject": n.get('subject', ''),
                     "module": n.get('module', ''), "summary": n.get('summary', ''),
                     "url": n.get('url'), "timestamp": n.get('timestamp')
                 })
        except: pass
             
        summaries_context = "\n".join([f"ID: {n['id']}, Sub: {n['subject']} {n['module']}, Summary: {n['summary']}" for n in found_notes[:15]])

        model = get_configured_model()
        prompt = f"""
        Act as KTU Professor. Topic: "{query}".
        Available Notes:
        {summaries_context}

        Task: Return JSON:
        {{
            "bestNoteId": "ID from list or null",
            "definitions": "Summary of topic...",
            "relatedQuestions": [],
            "pyqs": []
        }}
        """
        response = model.generate_content(prompt)
        clean_json = re.sub(r'```json|```', '', response.text).strip()
        ai_data = json.loads(clean_json)
        
        best_note_id = ai_data.get('bestNoteId')
        source_note_name = None
        matched_notes_list = []
        
        if best_note_id and best_note_id != "null":
            for n in found_notes:
                if str(best_note_id).lower() in str(n['id']).lower():
                    matched_notes_list.append(n)
                    source_note_name = f"{n['subject']} - {n['module']}"
                    break
        
        return jsonify({
            "notes": matched_notes_list,
            "sourceNoteName": source_note_name,
            "bestNoteId": best_note_id,
            "definitions": ai_data.get('definitions', ''),
            "relatedQuestions": ai_data.get('relatedQuestions', []),
            "pyqs": ai_data.get('pyqs', [])
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/explain-code', methods=['POST'])
def explain_code():
    try:
        data = request.get_json()
        code = data.get('code', '').strip()
        model = get_configured_model()
        prompt = f"Act as Senior CS Professor. Explain this code in Markdown:\n```\n{code}\n```"
        response = model.generate_content(prompt)
        return jsonify({"explanation": response.text.strip()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/ask-doubt', methods=['POST'])
def ask_doubt():
    try:
        data = request.get_json()
        query = data.get('query', '').strip()
        history = data.get('history', [])
        
        db = firestore.client()
        docs = db.collection('notes').where('status', '==', 'approved').stream()
        context_parts = [f"Sub: {n.get('subject')}, Mod: {n.get('module')}\nSummary: {n.get('summary')}" for n in [d.to_dict() for d in docs][:15]]
        context_str = "\n\n".join(context_parts)

        model = get_configured_model()
        system_instruction = f"""
        Act as KTU Tutor. Context:
        {context_str}
        Answer the doubt. State source reference (Subject/Module) if found.
        Start directly with answer. Under 200 words. Markdown.
        """
        
        chat = model.start_chat(history=history)
        response = chat.send_message(f"SYSTEM_INSTRUCTION:{system_instruction}\n\nQuestion: {query}")
        return jsonify({"answer": response.text.strip()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/generate-diagram', methods=['POST'])
def generate_diagram():
    try:
        data = request.get_json()
        topic = data.get('topic', '').strip()
        model = get_configured_model()
        prompt = f"Create a Mermaid.js diagram for: {topic}. Return ONLY raw Mermaid code. No markdown code blocks."
        response = model.generate_content(prompt)
        mermaid_code = response.text.replace('```mermaid', '').replace('```', '').strip()
        return jsonify({"mermaid_code": mermaid_code})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Global Error Handler
@app.errorhandler(Exception)
def handle_global_exception(e):
    traceback.print_exc()
    return jsonify({"error": "Internal Server Error", "details": str(e)}), 500

if __name__ == '__main__':
    # Running on port 5001 to avoid conflict with gemini-backend if running simultaneously
    print(f"Starting Gemma Backend with model: {OLLAMA_MODEL}")
    app.run(host='0.0.0.0', port=5001, debug=True)
