import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final List<dynamic> questions;

  QuizScreen({required this.questions});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int totalScore = 0;
  bool isAnswered = false;
  int? selectedIndex;

  void nextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        isAnswered = false;
        selectedIndex = null;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Quiz Completed!"),
        content: Text("Your Score: $totalScore / ${widget.questions.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Finish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var currentQuestion = widget.questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Assessment"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / widget.questions.length,
              backgroundColor: Colors.grey[200],
              color: Colors.purple,
            ),
            const SizedBox(height: 30),
            Text(
              "Question ${currentQuestionIndex + 1}:",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              currentQuestion['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: isAnswered
                        ? (index == currentQuestion['correctIndex']
                              ? Colors.green[100]
                              : (index == selectedIndex
                                    ? Colors.red[100]
                                    : null))
                        : null,
                    side: BorderSide(
                      color:
                          isAnswered && index == currentQuestion['correctIndex']
                          ? Colors.green
                          : Colors.grey[300]!,
                    ),
                  ),
                  onPressed: isAnswered
                      ? null
                      : () {
                          setState(() {
                            isAnswered = true;
                            selectedIndex = index;
                            if (index == currentQuestion['correctIndex']) {
                              totalScore++;
                            }
                          });
                        },
                  child: Text(
                    currentQuestion['options'][index],
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                ),
              );
            }),
            Spacer(),
            if (isAnswered)
              ElevatedButton(
                onPressed: nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text(
                  "Next Question",
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
