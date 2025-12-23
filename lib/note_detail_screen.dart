import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'quiz_screen.dart';
import 'participatory_study_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final String title, pdfUrl, summary;

  NoteDetailScreen({
    required this.title,
    required this.pdfUrl,
    required this.summary,
  });

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen>
    with SingleTickerProviderStateMixin {
  String? _localPath;
  bool _isLoading = true;
  String _loadingMessage = "Initializing...";
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _loadFile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = "Checking storage...";
    });

    try {
      final fileName =
          md5.convert(utf8.encode(widget.pdfUrl)).toString() + ".pdf";
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _localPath = file.path;
            _isLoading = false;
          });
        }
      } else {
        await _downloadFile(file);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = "Error: $e";
        });
      }
    }
  }

  Future<void> _downloadFile(File file) async {
    setState(() => _loadingMessage = "Downloading Note...\nAlmost there!");

    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          setState(() {
            _localPath = file.path;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to download PDF");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = "Download Failed. Please check internet.";
        });
      }
    }
  }

  Future<void> _generateAIQuiz(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: Colors.purple)),
    );

    try {
      final response = await http.post(
        Uri.parse('https://api-gemini-notes.onrender.com/generate-quiz'),
        headers: {'Content-Type': 'application/json'},

        body: json.encode({'text': widget.summary}),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        List<dynamic> questions = json.decode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(questions: questions),
          ),
        );
      } else {
        throw Exception(
          "Failed to load quiz. Status: ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("AI Error"),
          content: SingleChildScrollView(child: Text(e.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.teal),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.teal.withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 60,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          _loadingMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: 150,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.teal.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : (_localPath != null
                      ? SfPdfViewer.file(File(_localPath!))
                      : Center(child: Text("Unable to load PDF"))),
          ),
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
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _generateAIQuiz(context),
                        icon: Icon(Icons.psychology),
                        label: Text("Quiz"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ParticipatoryStudyScreen(
                                noteSummary: widget.summary,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.group_work),
                        label: Text("Co-Study"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  Expanded(
                    child: SingleChildScrollView(child: Text(widget.summary)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
