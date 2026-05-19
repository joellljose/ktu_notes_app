import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'note_detail_screen.dart';
import 'student_upload_screen.dart';

class NotesListScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  NotesListScreen({required this.subjectId, required this.subjectName});

  @override
  _NotesListScreenState createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  bool isProcessing = false;

  Future<void> uploadAndProcessWithAI() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => isProcessing = true);
      String filePath = result.files.single.path!;
      String fileName = result.files.single.name;

      try {
        var uri = Uri.parse('http://192.168.1.8:5000/process-note');
        var request = http.MultipartRequest('POST', uri);

        request.files.add(await http.MultipartFile.fromPath('file', filePath));

        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);

        if (response.statusCode == 200) {
          await FirebaseFirestore.instance.collection('notes').add({
            'subjectId': widget.subjectId,
            'title': fileName,
            'url': data['pdf_url'],
            'summary': data['summary'],
            'createdAt': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text("AI Note Generated Successfully!")),
          );
        } else {
          throw Exception("Server Error: ${data['error']}");
        }
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to process note.")),
        );
      } finally {
        setState(() => isProcessing = false);
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
    if (doc.exists) {
      await ref.delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from Favorites")));
    } else {
      await ref.set({
        'title': noteData['title'],
        'pdfUrl': noteData['url'],
        'summary': noteData['summary'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Favorites ❤️")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notes')
                .where('subjectId', isEqualTo: widget.subjectId)
                // Filter to show only approved notes (you can also allow the uploader to see their own pending notes if you want)
                // NOTE: You might need to add a composite index for this query.
                // Also, older notes don't have 'status', so we might need to handle null as approved, or update them.
                // For now, let's assume we filter if 'status' is not 'pending' and not 'rejected'.
                // But Firestore filtering is strict.
                // Safest is where('status', isEqualTo: 'approved') BUT that hides old notes without status.
                // Let's filter on client side for now to avoid losing old notes, or update old notes.
                // Given the constraints: Let's assume OLD notes are visible, NEW pending notes are hidden.
                // We can't query "where status != pending".
                // So we will fetch all and filter in the builder for now.
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              var allNotes = snapshot.data!.docs;
              // Client-side filtering to handle legacy data (no status field) + new pending notes
              var notes = allNotes.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String? status = data['status'];
                // Show if approved OR if status is missing (legacy)
                return status == 'approved' || status == null;
              }).toList();

              if (notes.isEmpty) {
                return Center(child: Text("No notes available. Upload one!"));
              }

              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  var noteDoc = notes[index];
                  var noteData = noteDoc.data() as Map<String, dynamic>;
                  final noteId = md5.convert(utf8.encode(noteData['url'] ?? '')).toString();

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('favorites')
                        .doc(noteId)
                        .snapshots(),
                    builder: (context, favSnapshot) {
                      bool isFav = favSnapshot.hasData && favSnapshot.data!.exists;

                      return ListTile(
                        leading: const Icon(Icons.description, color: Colors.teal, size: 20),
                        title: Text(noteData['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("AI Summary Available", style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            if (noteData['verifiedBy'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: noteData['verifiedBy'] == 'AI' ? Colors.purple[50] : Colors.green[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: noteData['verifiedBy'] == 'AI' ? Colors.purple : Colors.green,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  "Verified by ${noteData['verifiedBy']}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: noteData['verifiedBy'] == 'AI' ? Colors.purple : Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteDetailScreen(
                                title: noteData['title'],
                                pdfUrl: noteData['url'],
                                summary: noteData['summary'],
                              ),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.redAccent : Colors.grey,
                                size: 18,
                              ),
                              onPressed: () => _toggleFavorite(noteData),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: Colors.teal, size: 18),
                              tooltip: 'View AI Summary',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Row(
                                      children: [
                                        Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                                        SizedBox(width: 8),
                                        const Expanded(child: Text("AI Summary", style: TextStyle(fontSize: 18))),
                                      ],
                                    ),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            noteData['title'],
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                          ),
                                          const Divider(),
                                          Text(
                                            noteData['summary'] ?? "No summary available.",
                                            style: const TextStyle(fontSize: 15, height: 1.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          if (isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      "AI is reading and summarizing...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Student Upload Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StudentUploadScreen()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
        tooltip: "Upload Note",
      ),
    );
  }
}
