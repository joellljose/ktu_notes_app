import 'package:flutter/material.dart';
import 'auth_service.dart';

class DashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> branches = [
    {"name": "Computer Science", "icon": Icons.computer, "color": Colors.blue},
    {"name": "Electronics", "icon": Icons.memory, "color": Colors.orange},
    {"name": "Mechanical", "icon": Icons.settings, "color": Colors.red},
    {"name": "Civil", "icon": Icons.apartment, "color": Colors.green},
    {"name": "Electrical", "icon": Icons.electric_bolt, "color": Colors.amber},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Your Branch"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: branches.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // We will add navigation to Semester Selection here next
                print("Selected ${branches[index]['name']}");
              },
              child: Container(
                decoration: BoxDecoration(
                  color: branches[index]['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: branches[index]['color'], width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(branches[index]['icon'], size: 50, color: branches[index]['color']),
                    SizedBox(height: 10),
                    Text(
                      branches[index]['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}