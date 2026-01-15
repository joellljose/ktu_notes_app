import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:ai_ktu_notes_app/data/course_data.dart' as course_data;

class AdminUploadScreen extends StatefulWidget {
  @override
  _AdminUploadScreenState createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  bool _isGeneratingSummary = false;

  String selectedBranch = 'Computer Science';
  String selectedSem = 'S1';
  String selectedModule = 'Module 1';
  String? selectedSubject;

  List<String> branches = [
    'Computer Science',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
    'Common',
  ];
  List<String> semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  List<String> modules = [
    'Module 1',
    'Module 2',
    'Module 3',
    'Module 4',
    'Module 5',
    'Module 6',
  ];

  Future<void> _generateSummary() async {
    // We don't strictly need the URL for the SYLLABUS based summary,
    // but we do need the subject/module info.

    String finalSubject = getAvailableSubjects().isNotEmpty
        ? selectedSubject ?? ""
        : _subjectController.text.trim();

    if (finalSubject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select or enter a Subject first")),
      );
      return;
    }

    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      // Use your computer's IP (for emulator use 10.0.2.2, for physical device use your local IP)
      // Since this is a separate backend file running on 5001
      final apiUrl = Uri.parse(
        'https://summary-backend-ae35.onrender.com/generate-summary',
      );

      final response = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'subject': finalSubject,
          'module': selectedModule,
          'semester': selectedSem,
          'branch': selectedBranch,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _summaryController.text = data['summary'] ?? "No summary generated.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Summary Generated Successfully! ✨")),
        );
      } else {
        throw Exception("Failed: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error generating summary: $e")));
    } finally {
      setState(() {
        _isGeneratingSummary = false;
      });
    }
  }

  Map<String, Map<String, List<String>>> get courseData =>
      course_data.courseData;

  String convertToDirectLink(String originalUrl) {
    if (originalUrl.contains("drive.google.com")) {
      final RegExp regExp = RegExp(r"\/d\/([a-zA-Z0-9_-]+)\/");
      final match = regExp.firstMatch(originalUrl);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        return "https://drive.google.com/uc?export=download&id=$fileId";
      }
    }
    return originalUrl;
  }

  List<String> getAvailableSubjects() {
    if (courseData.containsKey(selectedBranch) &&
        courseData[selectedBranch]!.containsKey(selectedSem)) {
      return courseData[selectedBranch]![selectedSem]!;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableSubjects = getAvailableSubjects();

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Portal"),
        backgroundColor: Colors.orange[800],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedBranch,
                      items: branches
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(b, style: TextStyle(fontSize: 12)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedBranch = val as String;
                          selectedSubject = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Branch",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedSem,
                      items: semesters
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSem = val as String;
                          selectedSubject = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Sem",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              if (availableSubjects.isNotEmpty)
                DropdownButtonFormField(
                  value: selectedSubject,
                  hint: Text("Select Subject"),
                  isExpanded: true,
                  items: availableSubjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedSubject = val as String),
                  decoration: InputDecoration(
                    labelText: "Subject",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null ? "Select a subject" : null,
                )
              else
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: "Subject Name (Manual Entry)",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
              SizedBox(height: 15),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Note Title (e.g. Module 1 Part A)",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: "Paste Google Drive Link",
                  hintText: "https://drive.google.com/file/d/...",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 15),

              DropdownButtonFormField(
                value: selectedModule,
                items: modules
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => selectedModule = val as String),
                decoration: InputDecoration(
                  labelText: "Module",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _summaryController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "AI Summary",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingSummary ? null : _generateSummary,
                  icon: _isGeneratingSummary
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    _isGeneratingSummary
                        ? "Generating..."
                        : "Auto-Generate AI Summary",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String directUrl = convertToDirectLink(
                      _urlController.text.trim(),
                    );

                    String finalSubject = availableSubjects.isNotEmpty
                        ? selectedSubject!
                        : _subjectController.text.trim();

                    await FirebaseFirestore.instance.collection('notes').add({
                      'subject': finalSubject,
                      'title': _titleController.text.trim(),
                      'url': directUrl,
                      'branch': selectedBranch,
                      'semester': selectedSem,
                      'module': selectedModule,
                      'summary': _summaryController.text.trim(),
                      'createdAt': Timestamp.now(),
                      'uploadedAt': Timestamp.now(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Note published successfully!")),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  "PUBLISH NOTE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
