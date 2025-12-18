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
  final TextEditingController _subjectController = TextEditingController();

  String selectedBranch = 'Computer Science';
  String selectedSem = 'S1';
  String selectedModule = 'Module 1';

  List<String> branches = ['Computer Science', 'Electronics', 'Mechanical', 'Civil', 'Electrical', 'Common'];
  List<String> semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  List<String> modules = ['Module 1', 'Module 2', 'Module 3', 'Module 4', 'Module 5', 'Module 6'];

  // Logic to convert Drive "view" links to "direct download" links for the PDF Viewer
  String convertToDirectLink(String originalUrl) {
    if (originalUrl.contains("drive.google.com")) {
      final RegExp regExp = RegExp(r"\/d\/([a-zA-Z0-9_-]+)\/");
      final match = regExp.firstMatch(originalUrl);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        return "https://drive.google.com/uc?export=download&id=$fileId";
      }
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Portal"),
        backgroundColor: Colors.orange[800],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(labelText: "Subject Name (e.g. Engineering Physics)", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Note Title (e.g. Module 1 Part A)", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: "Paste Google Drive Link", 
                  hintText: "https://drive.google.com/file/d/...",
                  border: OutlineInputBorder()
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedBranch,
                      items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b, style: TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) => setState(() => selectedBranch = val as String),
                      decoration: InputDecoration(labelText: "Branch"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedSem,
                      items: semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => selectedSem = val as String),
                      decoration: InputDecoration(labelText: "Sem"),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              DropdownButtonFormField(
                value: selectedModule,
                items: modules.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => selectedModule = val as String),
                decoration: InputDecoration(labelText: "Module"),
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _summaryController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "AI Summary", 
                  alignLabelWithHint: true,
                  border: OutlineInputBorder()
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String directUrl = convertToDirectLink(_urlController.text.trim());
                    
                    await FirebaseFirestore.instance.collection('notes').add({
                      'subject': _subjectController.text.trim(),
                      'title': _titleController.text.trim(),
                      'url': directUrl,
                      'branch': selectedBranch,
                      'semester': selectedSem,
                      'module': selectedModule,
                      'summary': _summaryController.text.trim(),
                      'createdAt': Timestamp.now(),
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Note published successfully!")));
                    Navigator.pop(context);
                  }
                },
                child: Text("PUBLISH NOTE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}