import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_config.dart';
import 'package:ai_ktu_notes_app/data/course_data.dart';
import 'dart:async';

class TopicInsightsScreen extends StatefulWidget {
  @override
  _TopicInsightsScreenState createState() => _TopicInsightsScreenState();
}

class _TopicInsightsScreenState extends State<TopicInsightsScreen> {
  final TextEditingController _topicController = TextEditingController();
  bool _isLoading = false;
  double _loadingProgress = 0.0;
  Timer? _progressTimer;
  String _statusMessage = 'Initializing...';
  String _generatedPoints = '';
  String _errorMessage = '';
  String? _story;
  bool _isGeneratingStory = false;

  // Filter state
  String? userBranch;
  String? userSemester;
  String? selectedSubject;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
      _statusMessage = 'Analyzing topic...';
    });

    const messages = [
      'Extracting key concepts...',
      'Structuring insights...',
      'Generating study points...',
      'Refining content...',
      'Deepening analysis...',
    ];
    int msgIndex = 0;

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) return;
      setState(() {
        if (_loadingProgress < 75) {
          _loadingProgress += 2.2;
        } else if (_loadingProgress < 90) {
          _loadingProgress += 0.5;
        } else if (_loadingProgress < 98) {
          _loadingProgress += 0.05;
        }

        if (timer.tick % 18 == 0) {
          msgIndex = (msgIndex + 1) % messages.length;
          _statusMessage = messages[msgIndex];
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
    _topicController.dispose();
    super.dispose();
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

  Future<void> _generateInsights() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a topic to analyze.')),
      );
      return;
    }

    _startLoading();

    try {
      // Assuming backend is running locally on emulator/device or port 5000
      // Update with your actual server URL if deployed
      final uri = Uri.parse(ApiConfig.generateTopicPoints);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': topic,
          'subject': selectedSubject,
          'branch': userBranch ?? "",
          'semester': userSemester ?? "",
          'userId': FirebaseAuth.instance.currentUser?.uid,
        }),
      ).timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _generatedPoints = data['points_markdown'] ?? 'No points generated.';
        });
      } else {
        setState(() {
          _errorMessage = 'Server Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect: $e\nEnsure the Python backend is running.';
      });
    } finally {
      _stopLoading();
    }
  }

  Future<void> _generateStory() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic first.')),
      );
      return;
    }

    setState(() {
      _isGeneratingStory = true;
      _story = null;
    });

    try {
      final uri = Uri.parse(ApiConfig.generateCreativeHint);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': topic,
          'subject': selectedSubject,
          'branch': userBranch ?? "",
          'semester': userSemester ?? "",
          'userId': FirebaseAuth.instance.currentUser?.uid,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _story = data['hint'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Story mode failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingStory = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Insights'),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(selectedSubject == null ? Icons.tune : Icons.filter_alt, 
            color: selectedSubject == null ? Colors.white : Colors.orangeAccent),
            onPressed: _showSubjectPicker,
            tooltip: "Select Subject Context",
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Master any topic instantly.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal[800]),
            ),
            SizedBox(height: 8),
            Text(
              'Enter a complete topic or concept below. Our AI will extract the most critical exam-focused bullet points for KTU.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 10),
            
            if (selectedSubject != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Chip(
                  label: Text("Context: $selectedSubject", style: const TextStyle(fontSize: 12)),
                  onDeleted: () => setState(() => selectedSubject = null),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  backgroundColor: Colors.teal.withOpacity(0.1),
                ),
              ),

            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: 'e.g., Normalization in DBMS, Turing Machine',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
                prefixIcon: Icon(Icons.search, color: Colors.teal),
              ),
              onSubmitted: (_) => _generateInsights(),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateInsights,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Analyze Topic', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingStory ? null : _generateStory,
                    icon: _isGeneratingStory 
                      ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal))
                      : Icon(Icons.auto_awesome, size: 16, color: Colors.teal),
                    label: Text(
                      _isGeneratingStory ? 'Generating...' : 'Story Mode',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade50,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.teal.shade200),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent.withOpacity(0.05),
                            ),
                            child: CircularProgressIndicator(
                              value: _loadingProgress / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              color: Colors.blueAccent,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            "${_loadingProgress.toInt()}%",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Crafting KTU-focused study points",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
            if (_story != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.indigo, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "CREATIVE STORY MODE",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    MarkdownBody(
                      data: _story!,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_generatedPoints.isNotEmpty)
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: _generatedPoints,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        listBullet: TextStyle(fontSize: 18, color: Colors.teal),
                      ),
                    ),
                  ),
                ),
              ),
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
