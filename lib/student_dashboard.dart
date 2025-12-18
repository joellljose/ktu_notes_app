import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'note_detail_screen.dart';

class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return Scaffold(body: Center(child: Text("Not Logged In")));

    return Scaffold(
      appBar: AppBar(
        title: Text("My KTU Notes"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout), 
            onPressed: () => FirebaseAuth.instance.signOut()
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, userSnapshot) {
          // 1. Handle Loading State
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // 2. Handle Errors (like No Internet)
          if (userSnapshot.hasError) {
            return Center(child: Text("Error: ${userSnapshot.error}"));
          }

          // 3. Handle Missing Document (THIS IS YOUR ERROR FIX)
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Profile not found in Firestore."),
                  Text("Ensure you registered via the Signup Screen."),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: Text("Logout and Try Again"),
                  )
                ],
              ),
            );
          }

          // 4. Document exists, safe to get data
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String branch = userData['branch'] ?? "Not Set";
          String semester = userData['semester'] ?? "Not Set";

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Colors.blueAccent.withOpacity(0.1),
                child: Text(
                  "Showing notes for $branch - $semester",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notes')
                      .where('branch', isEqualTo: branch)
                      .where('semester', isEqualTo: semester)
                      .snapshots(),
                  builder: (context, noteSnapshot) {
                    if (noteSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!noteSnapshot.hasData || noteSnapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No notes uploaded for $branch $semester yet."));
                    }

                    var notes = noteSnapshot.data!.docs;

                    return ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        var noteData = notes[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                            title: Text(noteData['title'] ?? "Untitled"),
                            subtitle: Text("AI Summary available"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NoteDetailScreen(
                                    title: noteData['title'] ?? "Note",
                                    pdfUrl: noteData['url'] ?? "",
                                    summary: noteData['summary'] ?? "No summary available.",
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
              ),
            ],
          );
        },
      ),
    );
  }
}