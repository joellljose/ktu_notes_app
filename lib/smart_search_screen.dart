import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'note_detail_screen.dart'; // To open notes
import 'services/api_config.dart';
import 'package:ai_ktu_notes_app/data/course_data.dart';

class SmartSearchScreen extends StatefulWidget {
  @override
  _SmartSearchScreenState createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends State<SmartSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  double _loadingProgress = 0.0;
  String _statusMessage = 'Initializing...';
  Timer? _progressTimer;
  String _errorMessage = '';

  List<dynamic> _foundNotes = [];
  String? _sourceNoteName;
  String? _bestNoteId;
  String? _currentQuery;
  String _definitions = '';
  List<dynamic> _relatedQuestions = [];
  List<dynamic> _pyqs = [];
  String? _creativeHint;
  bool _isGeneratingHint = false;

  // Filter state
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
      _statusMessage = 'Searching notes...';
      _errorMessage = '';
      _foundNotes = [];
      _sourceNoteName = null;
      _definitions = '';
      _relatedQuestions = [];
      _pyqs = [];
    });

    const statusMessages = [
      'Scanning through relevant notes...',
      'Analyzing concepts...',
      'Consulting AI...',
      'Checking previous year questions...',
      'Organizing definitions...',
      'Synthesizing final answer...',
      'Just a few more seconds...',
    ];

    int messageIndex = 0;

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_loadingProgress < 75) {
          _loadingProgress += 2.0;
        } else if (_loadingProgress < 92) {
          _loadingProgress += 0.4;
        } else if (_loadingProgress < 99) {
          _loadingProgress += 0.02;
        }

        if (timer.tick % 15 == 0) {
          messageIndex = (messageIndex + 1) % statusMessages.length;
          _statusMessage = statusMessages[messageIndex];
        }
      });
    });
  }

  void _stopLoading() {
    _progressTimer?.cancel();
    if (mounted) {
      setState(() {
        _loadingProgress = 100;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic to search for.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    _startLoading();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.smartSearch),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'branch': userBranch ?? "Not Set",
          'semester': userSemester ?? "Not Set",
          'subject': selectedSubject ?? "General",
          'userId': FirebaseAuth.instance.currentUser?.uid,
        }),
      ).timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _foundNotes = data['notes'] ?? [];
          _sourceNoteName = data['sourceNoteName'];
          _bestNoteId = data['bestNoteId'];
          _currentQuery = query;
          _definitions = data['definitions'] ?? 'No definitions available.';
          _relatedQuestions = data['relatedQuestions'] ?? [];
          _pyqs = data['pyqs'] ?? [];
        });
      } else {
        setState(() => _errorMessage = 'Server Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Search failed: $e');
    } finally {
      _stopLoading();
    }
  }

  Future<void> _generateCreativeHint() async {
    final queryToHint = _currentQuery;
    if (queryToHint == null) return;

    setState(() {
      _isGeneratingHint = true;
      _creativeHint = null;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.generateCreativeHint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': queryToHint,
          'subject': selectedSubject ?? "General",
          'branch': userBranch ?? "Not Set",
          'semester': userSemester ?? "Not Set",
          'userId': FirebaseAuth.instance.currentUser?.uid,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _creativeHint = data['hint'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate hint: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating hint: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingHint = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> noteData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docId = md5.convert(utf8.encode(noteData['url'] ?? '')).toString();
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(docId);

    final doc = await ref.get();
    try {
      if (doc.exists) {
        await ref.delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Removed from Favorites")));
      } else {
        await ref.set({
          'title': noteData['subject'] ?? noteData['title'] ?? 'Note',
          'pdfUrl': noteData['url'],
          'summary': noteData['summary'] ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Added to Favorites ❤️")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildSectionTitle(String title, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? Colors.teal).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color ?? const Color.fromARGB(255, 0, 121, 107), size: 16),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterTopicHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "MASTER TOPIC",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Row(
                children: [
                  // Bell Icon: Allows users to subscribe to updates or set reminders for this specific topic
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Alert set for $_currentQuery 🔔"),
                        ),
                      );
                    },
                  ),
                  // Share Icon: Allows users to share the summarized AI insights and note links
                  IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            _currentQuery ?? "Search Result",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Comprehensive learning guide and resources",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Recommended Note section, directly linking to the best match
  Widget _buildBestMatchSection() {
    final bestNote = _foundNotes.firstWhere(
      (n) => n['id']?.toString() == _bestNoteId,
      orElse: () => null,
    );

    if (bestNote == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star, color: Colors.teal, size: 20),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recommended Note",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                    ),
                  ),
                  Text(
                    "The best resource for this topic",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          Divider(height: 24, color: Colors.teal.shade50),
          Text(
            bestNote['subject'] ?? 'Note',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            bestNote['module'] ?? '',
            style: TextStyle(fontSize: 14, color: Colors.teal.shade700),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (bestNote['url'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteDetailScreen(
                        title: bestNote['subject'] ?? 'Note',
                        pdfUrl: bestNote['url'],
                        summary: bestNote['summary'] ?? '',
                      ),
                    ),
                  );
                }
              },
              icon: Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
              label: Text("OPEN NOTE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeHintCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.indigo.shade100.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.indigo.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.auto_awesome,
                size: 100,
                color: Colors.indigo.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.psychology, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "STUDY HACK",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Text(
                                "Learn via Story/Analogy",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_creativeHint == null && !_isGeneratingHint)
                        TextButton.icon(
                          onPressed: _generateCreativeHint,
                          icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.indigo),
                          label: const Text(
                            "REVEAL",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isGeneratingHint)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
                            SizedBox(height: 12),
                            Text(
                              "Weaving a story for you...",
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.indigo, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_creativeHint != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: MarkdownBody(
                        data: _creativeHint!,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Search 🔎'),
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
        color: Colors.grey[50],
        child: Column(
          children: [
            // Search Bar Area
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  hintText: 'Search anything (e.g., Vertex Cover)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.teal),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send, color: Colors.teal),
                    onPressed: _performSearch,
                  ),
                ),
              ),
            ),

            if (selectedSubject != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Chip(
                  label: Text("Context: $selectedSubject", style: const TextStyle(fontSize: 12)),
                  onDeleted: () => setState(() => selectedSubject = null),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  backgroundColor: Colors.teal.withOpacity(0.1),
                ),
              ),

            // Results Area
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: CircularProgressIndicator(
                                    value: _loadingProgress / 100,
                                    strokeWidth: 10,
                                    backgroundColor: Colors.teal.withOpacity(
                                      0.1,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.teal,
                                    ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_stories,
                                      size: 40,
                                      color: Colors.teal,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "${_loadingProgress.toInt()}%",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 40),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 500),
                              child: Text(
                                _statusMessage,
                                key: ValueKey(_statusMessage),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.teal[800],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "This may take a few seconds",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : (_definitions.isEmpty && _foundNotes.isEmpty)
                  ? Center(
                      child: Text(
                        "Type a topic above to start searching.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        _buildMasterTopicHeader(),

                        _buildCreativeHintCard(),

                        if (_bestNoteId != null) _buildBestMatchSection(),

                        // Definitions Section
                        _buildSectionTitle(
                          "Definitions",
                          Icons.info_outline,
                          color: Colors.blue,
                        ),

                        // Source Note Highlight
                        if (_sourceNoteName != null)
                          Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.blue[800],
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: Colors.blue[900],
                                        fontSize: 13,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "Topic likely found in: ",
                                        ),
                                        TextSpan(
                                          text: _sourceNoteName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.teal.shade50),
                          ),
                          child: MarkdownBody(
                            data: _definitions,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                              h1: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[900],
                              ),
                              h2: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                          ),
                        ),

                        // Notes Section
                        if (_foundNotes.isNotEmpty) ...[
                          _buildSectionTitle(
                            "Related Study Material",
                            Icons.menu_book,
                            color: Colors.teal,
                          ),
                          ..._foundNotes.map((note) {
                            final noteId = md5
                                .convert(utf8.encode(note['url'] ?? ''))
                                .toString();
                            return Container(
                              margin: EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser?.uid)
                                    .collection('favorites')
                                    .doc(noteId)
                                    .snapshots(),
                                builder: (context, favSnapshot) {
                                  bool isFav =
                                      favSnapshot.hasData &&
                                      favSnapshot.data!.exists;
                                  return ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    tileColor: (note['id'] != null && note['id'].toString() == _bestNoteId) 
                                        ? Colors.teal.withOpacity(0.05) 
                                        : null,
                                    leading: Stack(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                        ),
                                        if (note['id'] != null && note['id'].toString() == _bestNoteId)
                                          Positioned(
                                            right: -2,
                                            bottom: -2,
                                            child: Container(
                                              padding: EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.teal,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            note['subject'] ?? 'Note',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (note['id'] != null && note['id'].toString() == _bestNoteId)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.teal,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              "BEST MATCH",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      note['module'] ?? '',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isFav
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isFav
                                                ? Colors.redAccent
                                                : Colors.grey,
                                            size: 18,
                                          ),
                                          onPressed: () =>
                                              _toggleFavorite(note),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      if (note['url'] != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                NoteDetailScreen(
                                                  title:
                                                      note['subject'] ?? 'Note',
                                                  pdfUrl: note['url'],
                                                  summary:
                                                      note['summary'] ?? '',
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ],

                        // Related Questions Section
                        if (_relatedQuestions.isNotEmpty) ...[
                          _buildSectionTitle(
                            "Practice Questions",
                            Icons.help_outline,
                            color: Colors.purple,
                          ),
                          ..._relatedQuestions
                              .map(
                                (q) => Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50.withOpacity(
                                      0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.purple.shade50,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.quiz_outlined,
                                        size: 18,
                                        color: Colors.purple[700],
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          q.toString(),
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.purple[900],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ],

                        // PYQs Section
                        if (_pyqs.isNotEmpty) ...[
                          _buildSectionTitle(
                            "Previous Year Questions",
                            Icons.history_edu,
                            color: Colors.orange,
                          ),
                          ..._pyqs
                              .map(
                                (q) => Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50]?.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.orange[700],
                                        size: 18,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          q.toString(),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.brown[900],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                        SizedBox(height: 40), // Bottom padding
                      ],
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
