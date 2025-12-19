import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'module_list_screen.dart';
import 'admin_upload_screen.dart';
import 'profile_screen.dart'; // Import your new Profile Screen
import 'community_chat_screen.dart';

class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Safety check if user session is lost
    if (user == null)
      return Scaffold(body: Center(child: Text("Not Logged In")));

    return Scaffold(
      appBar: AppBar(
        // SECRET ACCESS: Long press the title to enter Admin Upload Screen
        title: GestureDetector(
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminUploadScreen()),
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Entering Admin Mode...")));
          },
          child: Text("KTU Subjects"),
        ),
        backgroundColor: Colors.teal,
        actions: [
          // PROFILE ICON: Navigate to Profile Screen
          IconButton(
            icon: Icon(Icons.account_circle, size: 28),
            tooltip: "My Profile",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          // LOGOUT BUTTON
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch User profile to get their specific Branch and Semester
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError ||
              !userSnapshot.hasData ||
              !userSnapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Profile Error. Please check your connection."),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: Text("Logout"),
                  ),
                ],
              ),
            );
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String branch = userData['branch'] ?? "Not Set";
          String semester = userData['semester'] ?? "Not Set";

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header showing user's current status
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Colors.teal.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$semester | $branch",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.chat, color: Colors.teal),
                          tooltip: "Class Chat",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommunityChatScreen(
                                  branch: branch,
                                  semester: semester,
                                ),
                              ),
                            );
                          },
                        ),
                        Icon(Icons.school, color: Colors.teal, size: 20),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // QUERY LOGIC:
                  // If S1/S2, show 'Common' branch notes.
                  // If S3+, show notes matching their specific branch.
                  stream: (semester == 'S1' || semester == 'S2')
                      ? FirebaseFirestore.instance
                            .collection('notes')
                            .where('semester', isEqualTo: semester)
                            .snapshots()
                      : FirebaseFirestore.instance
                            .collection('notes')
                            .where('branch', isEqualTo: branch)
                            .where('semester', isEqualTo: semester)
                            .snapshots(),
                  builder: (context, noteSnapshot) {
                    if (noteSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    // 1. Safe data extraction to prevent crashes from old documents
                    var validDocs = noteSnapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data.containsKey('subject');
                    }).toList();

                    // 2. Extract Unique Subjects
                    var subjects = validDocs
                        .map((doc) => doc['subject'] as String)
                        .toSet()
                        .toList();

                    if (subjects.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "No subjects found for $semester $branch yet.\n\n(Admin must add notes with the correct branch/sem labels)",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent.withOpacity(
                                0.2,
                              ),
                              child: Icon(Icons.book, color: Colors.teal),
                            ),
                            title: Text(
                              subjects[index],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text("View all modules"),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ModuleListScreen(
                                    branch: branch,
                                    semester: semester,
                                    subject: subjects[index],
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
