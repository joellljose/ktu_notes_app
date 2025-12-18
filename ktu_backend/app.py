import cloudinary
import cloudinary.uploader
from flask import Flask, request, jsonify
from flask_cors import CORS
import fitz  # PyMuPDF for reading PDF text
from transformers import pipeline

app = Flask(__name__)
CORS(app)

# 1. PASTE YOUR CLOUDINARY DETAILS HERE
cloudinary.config( 
  cloud_name = "donmgynde", 
  api_key = "352199242217363", 
  api_secret = "ZhSLx5wZvRj4S_4v_64_kqb07ns",
  secure = True
)

# 2. Load the AI Model (This may take a minute on the first run)
print("Loading AI Model... Please wait.")
summarizer = pipeline("summarization", model="sshleifer/distilbart-cnn-12-6")

@app.route('/process-note', methods=['POST'])
def process_note():
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400
    
    file = request.files['file']
    
    try:
        # --- PART A: AI SUMMARIZATION ---
        # Read the PDF text directly from the uploaded file
        doc = fitz.open(stream=file.read(), filetype="pdf")
        text = ""
        for page in doc:
            text += page.get_text()
        
        # We process the first 1000 characters for the summary
        ai_input = text[:1024] 
        summary_result = summarizer(ai_input, max_length=150, min_length=50, do_sample=False)
        ai_summary = summary_result[0]['summary_text']

        # --- PART B: CLOUDINARY UPLOAD ---
        # Go back to the start of the file to upload it
        file.seek(0)
        upload_data = cloudinary.uploader.upload(file, resource_type="raw", folder="ktu_notes")
        pdf_url = upload_data.get("secure_url")

        return jsonify({
            "status": "success",
            "pdf_url": pdf_url,
            "summary": ai_summary
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Run the server. Using 0.0.0.0 allows your phone to connect
    app.run(host='0.0.0.0', port=5000, debug=True)