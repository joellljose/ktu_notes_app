import google.generativeai as genai
from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import re
import requests
import fitz  # PyMuPDF
import os

app = Flask(__name__)
CORS(app)

# --- CONFIGURATION ---
# It's better to use environment variables for keys in production, 
# but for now we keep the key here as per previous code.
API_KEY = "AIzaSyBUqB2SVmlrjyAgRdrDf0k73EbLZJqP3q4"
genai.configure(api_key=API_KEY)

# Use a consistent model
MODEL_NAME = 'gemini-2.5-flash' 

def extract_text_from_drive(url):
    """Downloads PDF from a URL and extracts text."""
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        response = requests.get(url, headers=headers, timeout=20)
        if response.status_code == 200:
            with fitz.open(stream=response.content, filetype="pdf") as doc:
                text = ""
                for page in doc:
                    text += page.get_text()
            return text
        else:
            raise Exception(f"Download failed with status: {response.status_code}")
    except Exception as e:
        raise Exception(f"Failed to extract text from PDF: {str(e)}")

@app.route('/generate-quiz', methods=['POST'])
def generate_quiz():
    try:
        data = request.get_json()
        input_text = data.get('text', '')
        pdf_url = data.get('url', '')
        
        source_text = ""

        # Determine source of text
        if input_text and input_text.strip():
            print("Generating quiz from provided description/text...")
            source_text = input_text
        elif pdf_url and pdf_url.strip():
            print(f"Generating quiz from PDF URL: {pdf_url}...")
            source_text = extract_text_from_drive(pdf_url)
        else:
            return jsonify({"error": "No text or PDF URL provided"}), 400

        if not source_text.strip():
             return jsonify({"error": "Extracted text is empty"}), 400

        # Initialize Model
        model = genai.GenerativeModel(model_name=MODEL_NAME)
        
        prompt = f"""
        Act as a University Professor. Generate 5 Multiple Choice Questions (MCQs) based on the following text.
        Return ONLY a JSON array of objects. No backticks. No markdown.
        
        Each object must have:
        - "question": The question string.
        - "options": A list of 4 distinct options strings.
        - "correctIndex": Integer (0-3) indicating the correct option.
        
        Text content:
        {source_text[:12000]}
        """

        # Generate content
        response = model.generate_content(prompt)
        
        # Clean and Parse
        clean_json = re.sub(r'```json|```', '', response.text).strip()
        quiz_data = json.loads(clean_json)
        
        return jsonify(quiz_data)

    except Exception as e:
        print(f"CRITICAL ERROR: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Listen on 0.0.0.0 so your phone/emulator can see the PC
    app.run(host='0.0.0.0', port=5000, debug=True)