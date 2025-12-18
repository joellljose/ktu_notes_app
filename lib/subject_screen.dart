import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notes_list_screen.dart'; // We will create this for the next step

class SubjectScreen extends StatelessWidget {
  final String branch;
  final String semester;

  SubjectScreen({required this.branch, required this.semester});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$semester - $branch"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query: Fetch only subjects that match the selected branch and semester
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .where('branch', isEqualTo: branch)
            .where('semester', isEqualTo: semester)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No subjects found for $semester"));
          }

          final subjectDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: subjectDocs.length,
            itemBuilder: (context, index) {
              var subject = subjectDocs[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(subject['name'][0], style: TextStyle(color: Colors.white)),
                  ),
                  title: Text(subject['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Code: ${subject['code']}"),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotesListScreen(
                          subjectId: subject.id,
                          subjectName: subject['name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}