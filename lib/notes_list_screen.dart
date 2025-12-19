//import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'note_detail_screen.dart';

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
    // 1. Select the PDF
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => isProcessing = true);
      String filePath = result.files.single.path!;
      String fileName = result.files.single.name;

      try {
        // 2. Prepare the Multipart Request for Python
        // REPLACE 'YOUR_PC_IP' with your actual IP address (e.g., 192.168.x.x)
        var uri = Uri.parse('http://192.168.1.8:5000/process-note');
        var request = http.MultipartRequest('POST', uri);

        request.files.add(await http.MultipartFile.fromPath('file', filePath));

        // 3. Send to Python and wait for AI Summary + Cloudinary URL
        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);

        if (response.statusCode == 200) {
          // 4. Save the results (URL and Summary) into Firestore
          await FirebaseFirestore.instance.collection('notes').add({
            'subjectId': widget.subjectId,
            'title': fileName,
            'url': data['pdf_url'],
            'summary': data['summary'],
            'createdAt': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("AI Note Generated Successfully!")),
          );
        } else {
          throw Exception("Server Error: ${data['error']}");
        }
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to process note.")));
      } finally {
        setState(() => isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: Stack(
        children: [
          // List of existing notes
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notes')
                .where('subjectId', isEqualTo: widget.subjectId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              var notes = snapshot.data!.docs;
              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.description, color: Colors.teal),
                    title: Text(notes[index]['title']),
                    subtitle: Text("AI Summary Available"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetailScreen(
                            title: notes[index]['title'],
                            pdfUrl: notes[index]['url'],
                            summary: notes[index]['summary'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          // Loading Overlay while AI is thinking
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
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
        onPressed: isProcessing ? null : uploadAndProcessWithAI,
        child: Icon(Icons.psychology), // "Brain" icon for AI
        backgroundColor: isProcessing ? Colors.grey : Colors.teal,
      ),
    );
  }
}
