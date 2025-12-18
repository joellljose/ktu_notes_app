import 'package:flutter/material.dart';

class SubjectScreen extends StatelessWidget {
  final String branch;
  final String semester;

  const SubjectScreen({Key? key, required this.branch, required this.semester})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$branch - $semester")),
      body: Center(
        child: Text("Subjects for $branch $semester will be listed here."),
      ),
    );
  }
}
