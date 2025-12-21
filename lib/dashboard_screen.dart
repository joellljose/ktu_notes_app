import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'semester_screen.dart';

class DashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> branches = [
    {"name": "Computer Science", "icon": Icons.computer, "color": Colors.teal},
    {"name": "Electronics", "icon": Icons.memory, "color": Colors.orange},
    {"name": "Mechanical", "icon": Icons.settings, "color": Colors.red},
    {"name": "Civil", "icon": Icons.apartment, "color": Colors.green},
    {"name": "Electrical", "icon": Icons.electric_bolt, "color": Colors.amber},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Branch"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: branches.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SemesterScreen(branchName: branches[index]['name']),
                  ),
                );
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
                    Icon(
                      branches[index]['icon'],
                      size: 50,
                      color: branches[index]['color'],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      branches[index]['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
