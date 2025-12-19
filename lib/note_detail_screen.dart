import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'quiz_screen.dart';

class NoteDetailScreen extends StatelessWidget {
  final String title, pdfUrl, summary;

  NoteDetailScreen({
    required this.title,
    required this.pdfUrl,
    required this.summary,
  });

  Future<void> _generateAIQuiz(BuildContext context) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: Colors.purple)),
    );

    try {
      // 10.0.2.2 is the special IP to reach your PC from the Android Emulator
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/generate-quiz'),
        headers: {'Content-Type': 'application/json'},
        // Send the summary text instead of the URL
        body: json.encode({'text': summary}),
      );

      Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        List<dynamic> questions = json.decode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(questions: questions),
          ),
        );
      } else {
        throw Exception("Failed to load quiz");
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("AI Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.blueAccent),
      body: Column(
        children: [
          Expanded(flex: 3, child: SfPdfViewer.network(pdfUrl)),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "AI Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _generateAIQuiz(context),
                        icon: Icon(Icons.psychology),
                        label: Text("Start AI Quiz"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  Expanded(child: SingleChildScrollView(child: Text(summary))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
