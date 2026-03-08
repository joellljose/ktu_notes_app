# Project Report: AI KTU Notes App

## 1. Abstract
The **AI KTU Notes App** is a next-generation educational platform designed to streamline the sharing and consumption of study materials for engineering students at **Kerala Technological University (KTU)**. Unlike traditional note-sharing platforms that suffer from unverified content and passive consumption, this system integrates **Generative AI (Google Gemini)** to automate quality control and enhance learning. The application features a cross-platform mobile interface built with **Flutter** and a robust **Python Flask** backend. Key innovations include automatic AI verification of uploaded PDF notes to ensure syllabus compliance, on-demand AI summarization of lengthy documents, and instant quiz generation for self-assessment. By bridging the gap between static content repositories and active learning tools, the project aims to improve academic outcomes and administrative efficiency.

## 2. Introduction
In the digital age, access to quality study material is crucial for academic success. However, students often struggle to find reliable, syllabus-aligned notes amidst a sea of unverified content shared across disparate channels like WhatsApp and Telegram. Administrators, on the other hand, face the overwhelming task of manually moderating thousands of uploads. The **AI KTU Notes App** addresses these challenges by creating a centralized, intelligent ecosystem. It automates the moderation process using Large Language Models (LLMs) and transforms static PDF notes into interactive learning resources, providing a modern solution to an age-old problem.

## 3. Objective
The primary objectives of this project are:
*   To create a centralized, cross-platform (Android/iOS/Windows) application for sharing KTU-specific engineering notes.
*   To implement **AI-powered content verification** that filters irrelevant or spam uploads without human intervention.
*   To specific **Active Learning** features such as automatic summarization of lecture notes and AI-generated quizzes.
*   To provide an **Admin Dashboard** for real-time monitoring of user activity, system health, and verification overrides.
*   To ensure a seamless user experience with real-time syncing, offline access, and push notifications.

## 4. Literature Survey
*   **Traditional Learning Management Systems (LMS):** Platforms like Moodle provide structured content but lack intelligent content analysis. They rely heavily on manual input and static file storage.
*   **Peer-to-Peer Sharing Networks:** Informal sharing via social media is fast but disorganized and prone to misinformation. Recent studies highlight the need for "moderated crowd-sourcing" in educational resources.
*   **Generative AI in Education:** Research by *OpenAI* and *Google* (2023-2024) demonstrates the efficacy of LLMs in summarizing technical content and generating evaluation metrics (quizzes). However, integration into real-time mobile workflows remains limited.
*   **Automated Content Moderation:** Existing solutions mostly focus on image/video safety (NSFW detection). Text-based syllabus compliance verification using semantic understanding is a novel application explored in this project.

## 5. Existing System
Currently, students rely on:
1.  **WhatsApp/Telegram Groups:** Unorganized, difficult to search, and links often expire.
2.  **Google Drive Folders:** Lack metadata (semester/subject tags) and version control.
3.  **Static Websites:** often outdated and riddled with ads.
**Limitations:**
*   **No Quality Control:** Anyone can upload incorrect or irrelevant files.
*   **Passive Consumption:** Students merely read PDFs without interactive engagement.
*   **Search Difficulty:** Finding a specific module's note is time-consuming.

## 6. Proposed System
The proposed **AI KTU Notes App** introduces:
1.  **Intelligent Upload Gateway:** Every note is scanned by Gemini AI. It reads the PDF, compares it against the selected Subject/Module, and auto-approves or rejects it.
2.  **Interactive Content:**
    *   **Summarizer:** "explain this to me efficiently" button.
    *   **Quizzer:** "Test me on this note" button.
3.  **Real-time Analytics:** Admins can see live user counts, upload trends, and active branches.


## 7. Modules

### 7.1 Authentication Module
*   **Function:** Secure user onboarding.
*   **Components:** Login Screen, Signup Screen.
*   **Tech:** Firebase Authentication (Email/Password).

### 7.2 Student Module
*   **Dashboard:** View notes filtered by Branch > Semester > Subject > Module.
*   **Upload Wizard:** 
    *   Pick PDF or Scan Application (Image-to-PDF).
    *   Real-time upload progress.
    *   AI Verification feedback loop (Approved/Rejected/Pending).
*   **Note Detail View:**
    *   Built-in PDF Viewer.
    *   **Generate Summary**: Calls backend to summarize the PDF.
    *   **Take Quiz**: Generates 5 MCQs based on the note's content.
*   **Participatory Learning:** Special mode for students to contribute questions or explain concepts.

### 7.3 Admin Module
*   **Live Dashboard:** Visualizations of active users, total notes, and branch distribution (Pie/Line Charts).
*   **Notes Manager:** Manual override for AI decisions (Approve/Delete pending notes).
*   **Notification Console:** Send push notifications (FCM) to all users.
*   **API Monitor:** Track usage of Gemini API keys to prevent quota exhaustion.

### 7.4 Backend Module (Service Layer)
*   **API Gateway:** Flask (Python) exposing REST endpoints.
*   **AI Engine:** Google Gemini Pro/Flash integration.
*   **Storage Service:** Cloudinary for file hosting (optimized for bandwidth).


## 8. Implementation Details

### Frontend (Mobile App)
*   **Framework:** Flutter (Dart).
*   **State Management:** `setState` & `StreamBuilder` for real-time Firestore updates.
*   **UI Library:** `GoogleFonts` (Poppins/FiraCode), `fl_chart` for analytics.
*   **PDF Handling:** `flutter_pdf_view` for viewing, `pdf` package for creating PDFs from images.

### Backend (Server)
*   **Language:** Python 3.9+.
*   **Framework:** Flask.
*   **AI Integration:** `google.generativeai` SDK.
    *   **Model:** `gemini-2.5-flash` for speed and efficiency.
    *   **Key Rotation:** Implements a round-robin strategy across multiple API keys to handle rate limits.
*   **Database:**
    *   **Fireworks Firestore:** Stores metadata (Subject, Title, URL, Uploader Info).
    *   **Cloudinary:** Stores actual PDF files (returned as secure URLs).
*   **Monitoring:** `APScheduler` runs periodic maintenance tasks.

### Key Algorithms
*   **Verification Algorithm:** 
    1. Extract text from first N pages of PDF.
    2. Construct prompt: "Act as Syllabus Validator. Subject: X. Content: Y."
    3. Parse JSON response: `{ "status": "approved", "reason": "..." }`.
*   **Load Balancing:** Random selection of available API keys for each request.

## 9. Conclusion
The **AI KTU Notes App** successfully demonstrates the potential of integrating Large Language Models into educational workflows. By automating the verification process, it reduces administrative burden by approximately 80% (estimated). The addition of active learning features like quizzes and summaries transforms the application from a passive storage bin into an active study companion. The system is robust, scalable, and user-friendly, providing a significant upgrade over existing manual solutions.

## 10. Future Enhancements
*   **Mobile App Release:** packaging the Flutter app into an APK/IPA for Play Store/App Store distribution.
*   **Offline Mode:** Caching PDFs locally for access without internet.
*   **Social Features:** Comments and upvotes on notes.
*   **Personalized Learning:** AI recommendations based on user's quiz performance (e.g., "You are weak in Module 2, study this note").
*   **Voice Notes:** Adding support for audio summaries.

## 11. References
1.  **Flutter Documentation:** https://flutter.dev/docs
2.  **Google Gemini API Docs:** https://ai.google.dev/
3.  **Firebase Documentation:** https://firebase.google.com/docs
4.  **Flask Documentation:** https://flask.palletsprojects.com/
5.  *Vaswani, A., et al. (2017). "Attention Is All You Need."* (Foundational Transformer Paper).
6.  *KTU Official Syllabus:* https://ktu.edu.in/
