import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool isSaving = false;

  String? selectedBranch;
  String? selectedSem;

  List<String> branches = [
    'Computer Science',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
    'Common',
  ];
  List<String> semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Profile"), backgroundColor: Colors.teal),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || !snapshot.data!.exists)
            return Center(child: Text("Error loading profile"));

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          // Initialize values if they are null
          selectedBranch ??= userData['branch'];
          selectedSem ??= userData['semester'];

          return Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  userData['email'],
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 30),

                // Edit Branch
                DropdownButtonFormField(
                  value: selectedBranch,
                  decoration: InputDecoration(
                    labelText: "Current Branch",
                    border: OutlineInputBorder(),
                  ),
                  items: branches
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedBranch = val as String),
                ),
                SizedBox(height: 20),

                // Edit Semester
                DropdownButtonFormField(
                  value: selectedSem,
                  decoration: InputDecoration(
                    labelText: "Current Semester",
                    border: OutlineInputBorder(),
                  ),
                  items: semesters
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedSem = val as String),
                ),
                SizedBox(height: 40),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .update({
                                'branch': selectedBranch,
                                'semester': selectedSem,
                              });
                          setState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Profile Updated!")),
                          );
                          Navigator.pop(context); // Go back after saving
                        },
                  child: isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "SAVE CHANGES",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
