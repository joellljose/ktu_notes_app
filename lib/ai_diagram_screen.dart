import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_config.dart';
import 'package:ai_ktu_notes_app/data/course_data.dart';
import 'dart:async';

class AiDiagramScreen extends StatefulWidget {
  @override
  _AiDiagramScreenState createState() => _AiDiagramScreenState();
}

class _AiDiagramScreenState extends State<AiDiagramScreen> {
  final TextEditingController _topicController = TextEditingController();
  late final WebViewController _webViewController;
  bool _isLoading = false;
  double _loadingProgress = 0.0;
  Timer? _progressTimer;
  String _statusMessage = 'Initializing...';
  String _mermaidCode = '';
  String? _errorMessage;

  // Filter state
  String? userBranch;
  String? userSemester;
  String? selectedSubject;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
      _statusMessage = 'Starting AI engine...';
    });

    const messages = [
      'Visualizing concepts...',
      'Mapping technical architecture...',
      'Generating Mermaid code...',
      'Finalizing diagram nodes...',
      'Optimizing layout...',
    ];
    int msgIndex = 0;

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) return;
      setState(() {
        if (_loadingProgress < 80) {
          _loadingProgress += 1.8;
        } else if (_loadingProgress < 95) {
          _loadingProgress += 0.3;
        } else if (_loadingProgress < 99) {
          _loadingProgress += 0.02;
        }

        if (timer.tick % 20 == 0) {
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

  @override
  void dispose() {
    _progressTimer?.cancel();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generateDiagram() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic for the diagram.')),
      );
      return;
    }

    _startLoading();
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.generateDiagram),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'topic': topic,
          'subject': selectedSubject,
          'branch': userBranch ?? "",
          'semester': userSemester ?? "",
          'userId': FirebaseAuth.instance.currentUser?.uid,
        }),
      ).timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final mermaidCode = data['mermaid_code'];
        
        _stopLoading();
        setState(() {
          _mermaidCode = mermaidCode;
        });
        
        _renderMermaidCode(mermaidCode);
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = errorData['error'] ?? 'Failed to generate diagram';
        });
        _stopLoading();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: Make sure the backend serves is accessible. ($e)';
      });
      _stopLoading();
    }
  }

  void _renderMermaidCode(String code) {
    // Clean up markdown block syntax
    String cleanCode = code.replaceAll(RegExp(r'```mermaid', caseSensitive: false), '')
                           .replaceAll(RegExp(r'```'), '')
                           .trim();

    // Use JSON encoding to safely generate a Javascript string literal. 
    // This perfectly escapes newlines, quotes, and special characters!
    String jsSafeCode = jsonEncode(cleanCode);

    final String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
        <script>
          mermaid.initialize({ 
            startOnLoad: false, 
            theme: 'default',
            securityLevel: 'loose',
            flowchart: { useMaxWidth: false, htmlLabels: true },
            sequence: { useMaxWidth: false },
            gantt: { useMaxWidth: false }
          });
        </script>
        <style>
          body { 
            margin: 0; 
            padding: 20px; 
            display: flex; 
            justify-content: center; 
            align-items: flex-start; 
            min-height: 100vh;
            background-color: white; /* Setting to white for better font anti-aliasing */
          }
          #graphDiv { 
            min-width: 100%; /* Ensure it takes space */
          }
          svg {
            max-width: 100% !important; /* Scale to fit width but maintain vector sharpness */
            height: auto !important;
          }
        </style>
      </head>
      <body>
        <div id="graphDiv"></div>
        <script>
           async function renderDiagram() {
             try {
                // The injected code is a valid JSON string, which is perfectly valid JS syntax.
                const code = $jsSafeCode;
                const { svg } = await mermaid.render('graphSvg', code);
                document.getElementById('graphDiv').innerHTML = svg;
             } catch (error) {
                document.getElementById('graphDiv').innerHTML = '<p style="color:red; text-align:center;">Syntax error in generated diagram code.</p>';
                console.error('Mermaid render error:', error);
             }
           }
           renderDiagram();
        </script>
      </body>
      </html>
    ''';

    _webViewController.loadHtmlString(htmlContent);
  }

  void _showZoomedDiagram() {
    if (_mermaidCode.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ZoomableDiagramView(mermaidCode: _mermaidCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagram Generator'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(selectedSubject == null ? Icons.tune : Icons.filter_alt, 
            color: selectedSubject == null ? Colors.white : Colors.orangeAccent),
            onPressed: _showSubjectPicker,
            tooltip: "Select Subject Context",
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _mermaidCode.isEmpty ? null : _showZoomedDiagram,
            tooltip: "View Full Screen",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_graph, color: Colors.blueAccent, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Type a concept (e.g., 'TCP Handshake', 'Binary Search Tree') to generate a visual flowchart diagram.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
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
                labelText: 'Diagram Topic',
                hintText: 'e.g., OSI Model Architecture',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _isLoading ? null : _generateDiagram,
                ),
              ),
              onSubmitted: (_) {
                  if (!_isLoading) _generateDiagram();
              },
            ),
            const SizedBox(height: 20),
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
                        "Crafting your visual concept guide",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else if (_mermaidCode.isNotEmpty)
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: WebViewWidget(controller: _webViewController),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: FloatingActionButton.small(
                        heroTag: 'zoomBtn',
                        onPressed: _showZoomedDiagram,
                        backgroundColor: Colors.teal.withOpacity(0.8),
                        child: const Icon(Icons.zoom_out_map, color: Colors.white),
                        tooltip: 'View Full Screen / Zoom',
                      ),
                    ),
                  ],
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    "Your diagram will appear here.",
                    style: TextStyle(color: Colors.grey),
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

class _ZoomableDiagramView extends StatefulWidget {
  final String mermaidCode;
  const _ZoomableDiagramView({required this.mermaidCode});

  @override
  __ZoomableDiagramViewState createState() => __ZoomableDiagramViewState();
}

class __ZoomableDiagramViewState extends State<_ZoomableDiagramView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true); // Enable native zoom
    _render();
  }

  void _render() {
    String cleanCode = widget.mermaidCode.replaceAll(RegExp(r'```mermaid', caseSensitive: false), '')
                           .replaceAll(RegExp(r'```'), '')
                           .trim();
    String jsSafeCode = jsonEncode(cleanCode);

    final String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
        <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
        <script>
          mermaid.initialize({ 
            securityLevel: 'loose',
            flowchart: { useMaxWidth: false, htmlLabels: true }
          });
        </script>
        <style>
          body { 
            margin: 0; 
            padding: 40px; 
            display: flex; 
            justify-content: center; 
            align-items: flex-start; 
            min-height: 100vh;
          }
          #graphDiv { width: 100%; }
        </style>
      </head>
      <body>
        <div id="graphDiv"></div>
        <script>
           async function renderDiagram() {
             try {
                const code = $jsSafeCode;
                const { svg } = await mermaid.render('graphSvg', code);
                document.getElementById('graphDiv').innerHTML = svg;
             } catch (error) {
                document.getElementById('graphDiv').innerHTML = '<p style="color:red;">Render Error</p>';
             }
           }
           renderDiagram();
        </script>
      </body>
      </html>
    ''';
    _controller.loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoom View'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Container(
        color: Colors.white,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
