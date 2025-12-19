import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'note_detail_screen.dart';

class ModuleListScreen extends StatelessWidget {
  final String branch, semester, subject;
  ModuleListScreen({
    required this.branch,
    required this.semester,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(subject),
          backgroundColor: Colors.teal,
          bottom: TabBar(
            isScrollable: true,
            tabs: List.generate(6, (i) => Tab(text: "Module ${i + 1}")),
          ),
        ),
        body: TabBarView(
          children: List.generate(6, (i) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notes')
                  .where('subject', isEqualTo: subject)
                  .where('module', isEqualTo: "Module ${i + 1}")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;

                if (docs.isEmpty)
                  return Center(child: Text("No notes in Module ${i + 1}"));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Icon(Icons.description, color: Colors.redAccent),
                      title: Text(data['title'] ?? "Untitled Note"),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetailScreen(
                            title: data['title'] ?? "Note",
                            pdfUrl: data['url'] ?? "",
                            summary: data['summary'] ?? "No summary.",
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
