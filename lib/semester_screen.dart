import 'package:flutter/material.dart';
import 'package:ai_ktu_notes_app/subject_screen.dart';

class SemesterScreen extends StatelessWidget {
  final String branchName;

  const SemesterScreen({super.key, required this.branchName});

  static const List<String> semesters = [
    "Semester 1",
    "Semester 2",
    "Semester 3",
    "Semester 4",
    "Semester 5",
    "Semester 6",
    "Semester 7",
    "Semester 8",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$branchName - Semesters")),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: semesters.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(semesters[index], style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectScreen(
                    branch: branchName,
                    semester: semesters[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
