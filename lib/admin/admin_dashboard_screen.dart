import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_view.dart';
import 'notes_manager_view.dart';
import '../login_screen.dart'; // Import LoginScreen for navigation after logout

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [DashboardView(), NotesManagerView()];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile Layout: BottomNavigationBar
          return Scaffold(
            appBar: AppBar(
              title: Text("Admin Panel", style: GoogleFonts.poppins()),
              backgroundColor: Colors.teal,
              actions: [
                IconButton(icon: Icon(Icons.logout), onPressed: _logout),
              ],
            ),
            backgroundColor: Color(0xFFF5F7FA),
            body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: Colors.teal,
              unselectedItemColor: Colors.grey,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: "Overview",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_books),
                  label: "Notes",
                ),
              ],
            ),
          );
        } else {
          // Desktop Layout: NavigationRail
          return Scaffold(
            backgroundColor: Color(0xFFF5F7FA),
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: Color(0xFF1E1E2C),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.teal,
                      size: 40,
                    ),
                  ),
                  labelType: NavigationRailLabelType.all,
                  unselectedLabelTextStyle: TextStyle(color: Colors.white54),
                  selectedLabelTextStyle: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard, color: Colors.white54),
                      selectedIcon: Icon(Icons.dashboard, color: Colors.teal),
                      label: Text("Overview"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.library_books, color: Colors.white54),
                      selectedIcon: Icon(
                        Icons.library_books,
                        color: Colors.teal,
                      ),
                      label: Text("Notes"),
                    ),
                  ],
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: IconButton(
                          icon: Icon(Icons.logout, color: Colors.red),
                          onPressed: _logout,
                        ),
                      ),
                    ),
                  ),
                ),
                VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          );
        }
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // After logout, AuthGate will handle showing LoginScreen,
    // but explicit navigation helps clear state if needed.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }
}
