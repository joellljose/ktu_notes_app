// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Manually providing options to fix the PlatformException
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCvYF6pEvsXkCaJFLOqWoAU1W-F6-X_wfQ",
      appId: "1:171227597422:android:94b2120978d2bb7ba5747f",
      messagingSenderId: "171227597422",
      projectId: "ai-ktu-notes-app",
      storageBucket: "ai-ktu-notes-app.firebasestorage.app",
    ),
  );

  runApp(KTUNotesApp());
}

// Update this part in your main.dart
class KTUNotesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primarySwatch: Colors.blue,
      ),
      home: AuthGate(), // Changed this line
    );
  }
}
