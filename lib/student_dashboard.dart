import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'module_list_screen.dart';
import 'admin_upload_screen.dart';

class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Scaffold(body: Center(child: Text("Not Logged In")));

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUploadScreen())),
          child: Text("KTU Subjects"),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) return Center(child: Text("Profile not found."));
          
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String branch = userData['branch'] ?? "Not Set";
          String semester = userData['semester'] ?? "Not Set";

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('notes')
                .where('semester', isEqualTo: semester)
                .where('branch', whereIn: [branch, 'Common'])
                .snapshots(),
            builder: (context, noteSnapshot) {
              if (noteSnapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
              
              // Filter documents to ensure 'subject' exists to avoid Bad State errors
              var validDocs = noteSnapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return data.containsKey('subject');
              }).toList();

              var subjects = validDocs.map((doc) => doc['subject'] as String).toSet().toList();

              if (subjects.isEmpty) return Center(child: Text("No subjects for $semester yet."));

              return ListView.builder(
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Icon(Icons.menu_book, color: Colors.blueAccent),
                      title: Text(subjects[index], style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (context) => ModuleListScreen(
                          branch: branch,
                          semester: semester,
                          subject: subjects[index],
                        ),
                      )),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}