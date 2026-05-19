class ApiConfig {
  // --- Hosted Render URL (Gemini Features) ---
  static const String renderUrl = 'https://api-gemini-notes-1.onrender.com';
  

  // --- Local ngrok URL (Moderation & Gemma) ---
  // Replace this with your latest ngrok URL when running locally
  static const String localNgrokUrl = 'https://leonor-unsoporific-admiratively.ngrok-free.dev';

  // Backends
  static const String geminiBaseUrl = renderUrl; // Direct to Render
  static const String gemmaBaseUrl = '$localNgrokUrl/gemma'; // Local via Gateway/ngrok
  static const String moderationBaseUrl = '$localNgrokUrl/moderation'; // Local via Gateway/ngrok

  // Gemini specific endpoints (Running on Render)
  static const String verifyNote = '$geminiBaseUrl/verify-note';
  static const String generateSummary = '$geminiBaseUrl/generate-summary';
  static const String generateQuiz = '$geminiBaseUrl/generate-quiz';
  static const String generateTopicPoints = '$geminiBaseUrl/generate-topic-points';
  static const String smartSearch = '$geminiBaseUrl/smart-search';
  static const String explainCode = '$geminiBaseUrl/explain-code';
  static const String askDoubt = '$geminiBaseUrl/ask-doubt';
  static const String generateDiagram = '$geminiBaseUrl/generate-diagram';
  static const String participatoryStart = '$geminiBaseUrl/participatory-start';
  static const String participatoryEvaluate = '$geminiBaseUrl/participatory-evaluate';
  static const String sendNotification = '$geminiBaseUrl/send-notification';
  static const String generateCreativeHint = '$geminiBaseUrl/generate-creative-hint';
  
  // Custom Gemma backend specific (Local only)
  static const String gemmaSmartSearch = '$gemmaBaseUrl/smart-search';

  // Moderation specific (Local only)
  static const String moderateMessage = '$moderationBaseUrl/moderate-message';
}
