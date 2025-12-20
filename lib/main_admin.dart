import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin/admin_login_screen.dart';
import 'admin/admin_dashboard_screen.dart';

// Separate entry point for Admin Panel
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCvYF6pEvsXkCaJFLOqWoAU1W-F6-X_wfQ",
      appId: "1:171227597422:android:94b2120978d2bb7ba5747f",
      messagingSenderId: "171227597422",
      projectId: "ai-ktu-notes-app",
      storageBucket: "ai-ktu-notes-app.firebasestorage.app",
    ),
  );

  runApp(AdminApp());
}

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KTU Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Color(0xFFF5F7FA), // Light grey background
      ),
      // Directly start at Admin Login
      home: AdminLoginScreen(),
      routes: {
        '/admin/login': (context) => AdminLoginScreen(),
        '/admin/dashboard': (context) => AdminDashboardScreen(),
      },
    );
  }
}
