import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Make sure this is imported

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has user data, they are logged in
        if (snapshot.hasData) {
          return Scaffold(
            body: Center(child: Text("Welcome! You are logged in.")),
          );
        }

        // Otherwise, show the Login Screen
        return LoginScreen();
      },
    );
  }
}