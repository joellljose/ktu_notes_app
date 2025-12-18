import 'package:flutter/material.dart';

class NotesListScreen extends StatelessWidget {
  final String subjectId;
  final String subjectName;

  NotesListScreen({required this.subjectId, required this.subjectName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$subjectName Notes")),
      body: Center(child: Text("Notes for $subjectName will appear here.")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // This is where we will add the PDF Upload feature next!
        },
        child: Icon(Icons.add),
        tooltip: "Upload Note",
      ),
    );
  }
}