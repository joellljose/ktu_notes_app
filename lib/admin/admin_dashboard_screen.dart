import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_view.dart';
import 'notes_manager_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [DashboardView(), NotesManagerView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Sidebar
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
                selectedIcon: Icon(Icons.library_books, color: Colors.teal),
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
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/admin/login');
                    },
                  ),
                ),
              ),
            ),
          ),
          VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
