import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ParticipatoryStudyScreen extends StatefulWidget {
  final String noteSummary;

  const ParticipatoryStudyScreen({Key? key, required this.noteSummary})
    : super(key: key);

  @override
  _ParticipatoryStudyScreenState createState() =>
      _ParticipatoryStudyScreenState();
}

class _ParticipatoryStudyScreenState extends State<ParticipatoryStudyScreen> {
  // 0: Loading Start, 1: Challenge Active, 2: Loading Feedback, 3: Feedback Result
  int _currentState = 0;

  // Data from Start
  String _intro = "";
  String _challenge = "";
  String _creationTask = "";

  // Data from Feedback
  String _conceptFeedback = "";
  String _questionCritique = "";
  String _score = "";

  // User Inputs
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    try {
      final response = await http.post(
        Uri.parse('https://api-gemini-notes.onrender.com/participatory-start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': widget.noteSummary}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _intro = data['facilitator_intro'];
          _challenge = data['challenge'];
          _creationTask = data['creation_task'];
          _currentState = 1;
        });
      } else {
        _showError("Failed to start session");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  Future<void> _submitResponses() async {
    setState(() => _currentState = 2);

    try {
      final response = await http.post(
        Uri.parse(
          'https://api-gemini-notes.onrender.com/participatory-evaluate',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': widget.noteSummary,
          'answer': _answerController.text,
          'question': _questionController.text,
          'challenge': _challenge,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _conceptFeedback = data['concept_feedback'];
          _questionCritique = data['question_critique'];
          _score = data['overall_score'];
          _currentState = 3;
        });
      } else {
        _showError("Failed to evaluate");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Collaborative Study"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentState == 0) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 20),
            Text("Connecting to AI Facilitator..."),
          ],
        ),
      );
    } else if (_currentState == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facilitator Intro
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal),
            ),
            child: Row(
              children: [
                Icon(Icons.person_pin, color: Colors.teal, size: 40),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _intro,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Challenge Section
          Text(
            "1. Concept Challenge",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(_challenge, style: TextStyle(fontSize: 16)),
          SizedBox(height: 10),
          TextField(
            controller: _answerController,
            decoration: InputDecoration(
              labelText: "Identify the missing part...",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          SizedBox(height: 30),

          // Creation Task
          Text(
            "2. Question Design Task",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(_creationTask, style: TextStyle(fontSize: 16)),
          SizedBox(height: 10),
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              labelText: "Write your tricky MCQ here...",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitResponses,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Submit for Review",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ),
        ],
      );
    } else if (_currentState == 2) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 20),
            Text("Analyzing your input..."),
          ],
        ),
      );
    } else {
      // Feedback State
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text("Overall Score", style: TextStyle(color: Colors.grey)),
                Text(
                  "$_score / 10",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          SizedBox(height: 10),
          Text(
            "Concept Feedback",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 5),
          Text(_conceptFeedback),
          SizedBox(height: 20),
          Text(
            "Question Critique",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 5),
          Text(_questionCritique),

          SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Finish Session"),
            ),
          ),
        ],
      );
    }
  }
}
