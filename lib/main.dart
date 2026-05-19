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
import 'firebase_options.dart';

// Global state for theme management
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: currentMode,
            theme: ThemeData(
              brightness: Brightness.light,
              textTheme: GoogleFonts.poppinsTextTheme(),
              primarySwatch: Colors.teal,
              appBarTheme: AppBarTheme(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
              primarySwatch: Colors.teal,
              scaffoldBackgroundColor: Colors.grey[900],
              appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900], foregroundColor: Colors.white),
              cardColor: Colors.grey[850],
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
          );
        }
      ),
    );
  }
}
