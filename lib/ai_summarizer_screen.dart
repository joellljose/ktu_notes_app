import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_ktu_notes_app/data/course_data.dart';
import 'services/api_config.dart';
import 'dart:async';

class AiSummarizerScreen extends StatefulWidget {
  @override
  _AiSummarizerScreenState createState() => _AiSummarizerScreenState();
}

class _AiSummarizerScreenState extends State<AiSummarizerScreen> {
  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;
  double _loadingProgress = 0.0;
  Timer? _progressTimer;
  String _summary = '';
  String _selectedLength = 'medium';
  
  // Selection state
  String? userBranch;
  String? userSemester;
  String? selectedSubject;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          userBranch = doc.data()?['branch'];
          userSemester = doc.data()?['semester'];
        });
      }
    }
  }

  List<String> getAvailableSubjects() {
    if (userBranch != null && userSemester != null &&
        courseData.containsKey(userBranch) &&
        courseData[userBranch]!.containsKey(userSemester)) {
      return courseData[userBranch]![userSemester]!;
    }
    return [];
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
    });
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_loadingProgress < 70) {
          _loadingProgress += 1.5;
        } else if (_loadingProgress < 90) {
          _loadingProgress += 0.5;
        } else if (_loadingProgress < 98) {
          _loadingProgress += 0.05;
        }
      });
    });
  }

  void _stopLoading() {
    _progressTimer?.cancel();
    setState(() {
      _loadingProgress = 100.0;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
        _summary = ''; // Clear previous summary
      });
    }
  }

  Future<void> _generateSummary() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a PDF file first.")),
      );
      return;
    }

    _startLoading();
    FocusScope.of(context).unfocus();

    try {
      // 1. Upload to get temporary URL (reusing verify-note endpoint for its upload capability)
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.verifyNote));
      request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));
      request.fields['subject'] = selectedSubject ?? "General";
      request.fields['branch'] = userBranch ?? "";
      request.fields['semester'] = userSemester ?? "";
      
      final streamedResponse = await request.send();
      final responseData = await streamedResponse.stream.bytesToString();
      
      if (streamedResponse.statusCode == 200) {
        final data = json.decode(responseData);
        final fileUrl = data['url'];

        // 2. Request custom summary with selected length
        final summaryResp = await http.post(
          Uri.parse(ApiConfig.generateSummary),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'url': fileUrl,
            'length': _selectedLength,
            'subject': selectedSubject,
            'branch': userBranch,
            'semester': userSemester,
            'userId': FirebaseAuth.instance.currentUser?.uid,
          }),
        ).timeout(const Duration(seconds: 300));

        if (summaryResp.statusCode == 200) {
          final summaryData = json.decode(summaryResp.body);
          setState(() {
            _summary = summaryData['summary'];
          });
        } else {
          throw Exception("Failed to generate summary");
        }
      } else {
        throw Exception("Failed to upload file");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      _stopLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Notes Summarizer"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(selectedSubject == null ? Icons.tune : Icons.filter_alt, 
            color: selectedSubject == null ? Colors.white : Colors.orangeAccent),
            onPressed: _showSubjectPicker,
            tooltip: "Select Subject Context",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Box
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.withOpacity(0.2), width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile == null ? Icons.cloud_upload_outlined : Icons.picture_as_pdf,
                      size: 48,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile == null ? "Tap to upload study material (PDF)" : _fileName!,
                      style: TextStyle(
                        color: Colors.teal.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (selectedSubject != null)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Chip(
                  label: Text("Context: $selectedSubject", style: const TextStyle(fontSize: 12)),
                  onDeleted: () => setState(() => selectedSubject = null),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  backgroundColor: Colors.teal.withOpacity(0.1),
                ),
              ),

            const SizedBox(height: 10),
            
            // Length Selection
            const Text(
              "Select Summary Depth:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'short', label: Text("Short"), icon: Icon(Icons.flash_on, size: 16)),
                ButtonSegment(value: 'medium', label: Text("Medium"), icon: Icon(Icons.article, size: 16)),
                ButtonSegment(value: 'detailed', label: Text("Detailed"), icon: Icon(Icons.description, size: 16)),
              ],
              selected: {_selectedLength},
              onSelectionChanged: (newSelection) {
                setState(() => _selectedLength = newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.teal,
                selectedForegroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _generateSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text("Summarizing... ${_loadingProgress.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                : const Text("Generate AI Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            
            const SizedBox(height: 30),
            
            // Result Area
            if (_summary.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("AI Generated Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                    onPressed: () {
                      // Copy to clipboard logic
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withOpacity(0.1)),
                ),
                child: MarkdownBody(
                  data: _summary,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSubjectPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final subjects = getAvailableSubjects();
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Subject Context", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Showing subjects for $userBranch ($userSemester)", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              if (subjects.isEmpty)
                const Center(child: Text("No subjects found for your profile."))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final s = subjects[index];
                      return ListTile(
                        title: Text(s, style: const TextStyle(fontSize: 14)),
                        onTap: () {
                          setState(() => selectedSubject = s);
                          Navigator.pop(context);
                        },
                        trailing: selectedSubject == s ? const Icon(Icons.check_circle, color: Colors.teal) : null,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
