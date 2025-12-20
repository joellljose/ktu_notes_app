import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'student_dashboard.dart';
import 'admin/admin_dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // User is logged in, check their role
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                print("DEBUG: User ID: ${snapshot.data!.uid}");
                print("DEBUG: Full Protocol Data: $userData");

                String role = userData['role'] ?? 'student';
                print("DEBUG: Fetched Role: $role");

                if (role == 'admin') {
                  return AdminDashboardScreen();
                } else {
                  return StudentDashboard();
                }
              } else {
                print(
                  "DEBUG: User document does not exist for ID: ${snapshot.data!.uid}",
                );
              }

              // Default fallback if user doc missing (new user?) -> Student
              return StudentDashboard();
            },
          );
        }

        // User not logged in
        return LoginScreen();
      },
    );
  }
}
