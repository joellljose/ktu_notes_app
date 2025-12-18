import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUploadScreen extends StatefulWidget {
  @override
  _AdminUploadScreenState createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  String selectedBranch = 'Computer Science';
  String selectedSem = 'S1';

  List<String> branches = ['Computer Science', 'Electronics', 'Mechanical', 'Civil', 'Electrical', 'Common'];
  List<String> semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin: Add New Note")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Note Title (e.g. Module 1)", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Enter title" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(labelText: "Cloudinary PDF URL", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Enter URL" : null,
              ),
              SizedBox(height: 15),
              DropdownButtonFormField(
                value: selectedBranch,
                items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => setState(() => selectedBranch = val as String),
                decoration: InputDecoration(labelText: "Target Branch", border: OutlineInputBorder()),
              ),
              SizedBox(height: 15),
              DropdownButtonFormField(
                value: selectedSem,
                items: semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => selectedSem = val as String),
                decoration: InputDecoration(labelText: "Target Semester", border: OutlineInputBorder()),
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _summaryController,
                maxLines: 5,
                decoration: InputDecoration(labelText: "AI Summary (Paste from Python)", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Enter summary" : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: Size(double.infinity, 50)),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await FirebaseFirestore.instance.collection('notes').add({
                      'title': _titleController.text.trim(),
                      'url': _urlController.text.trim(),
                      'branch': selectedBranch,
                      'semester': selectedSem,
                      'summary': _summaryController.text.trim(),
                      'createdAt': Timestamp.now(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Note Added Successfully!")));
                    Navigator.pop(context);
                  }
                },
                child: Text("PUBLISH TO STUDENTS", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}