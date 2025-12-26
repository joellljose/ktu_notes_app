import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'no_internet_screen.dart';
import 'splash_screen.dart';

import 'admin/admin_dashboard_screen.dart';

import 'services/user_activity_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyCvXII1XF6_FWWYYfhpypNQS5sw1txExwY",
            appId: "1:171227597422:web:e20213b7f3cfea2ba5747f",
            messagingSenderId: "171227597422",
            projectId: "ai-ktu-notes-app",
            storageBucket: "ai-ktu-notes-app.firebasestorage.app",
            authDomain: "ai-ktu-notes-app.firebaseapp.com",
            measurementId: "G-PNJ98N6WCD",
          )
        : const FirebaseOptions(
            apiKey: "AIzaSyCvYF6pEvsXkCaJFLOqWoAU1W-F6-X_wfQ",
            appId: "1:171227597422:android:94b2120978d2bb7ba5747f",
            messagingSenderId: "171227597422",
            projectId: "ai-ktu-notes-app",
            storageBucket: "ai-ktu-notes-app.firebasestorage.app",
          ),
  );

  UserActivityService().init();
  try {
    await NotificationService().initNotifications();
  } catch (e) {
    if (kDebugMode) {
      print("Error initializing notifications: $e");
    }
  }

  runApp(KTUNotesApp());
}

class KTUNotesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => UserActivityService().logClick(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(),
          primarySwatch: Colors.teal,
        ),
        builder: (context, child) {
          return StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              final connectivityResult = snapshot.data;
              if (connectivityResult != null &&
                  (connectivityResult.contains(ConnectivityResult.none) ||
                      connectivityResult.isEmpty)) {
                return NoInternetScreen();
              }
              return child ?? SizedBox();
            },
          );
        },
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/admin/dashboard': (context) => AdminDashboardScreen(),
        },
      ),
    );
  }
}
