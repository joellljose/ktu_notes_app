import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:ai_ktu_notes_app/data/course_data.dart';

class StudentUploadScreen extends StatefulWidget {
  @override
  _StudentUploadScreenState createState() => _StudentUploadScreenState();
}

class _StudentUploadScreenState extends State<StudentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;

  // Reuse the same course data structure
  String selectedBranch = 'Computer Science';
  String selectedSem = 'S1';
  String selectedModule = 'Module 1';
  String? selectedSubject;

  final List<String> branches = [
    'Computer Science',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
    'Common',
  ];
  final List<String> semesters = [
    'S1',
    'S2',
    'S3',
    'S4',
    'S5',
    'S6',
    'S7',
    'S8',
  ];
  final List<String> modules = [
    'Module 1',
    'Module 2',
    'Module 3',
    'Module 4',
    'Module 5',
  ];

  // Use the imported courseData from lib/data/course_data.dart instead of local definition

  List<String> getAvailableSubjects() {
    if (courseData.containsKey(selectedBranch) &&
        courseData[selectedBranch]!.containsKey(selectedSem)) {
      return courseData[selectedBranch]![selectedSem]!;
    }
    return [];
  }

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _scanAndCreatePDF() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Converting ${images.length} images to PDF...")),
      );

      final pdf = pw.Document();

      for (var image in images) {
        final imageFile = File(image.path);
        final imageBytes = await imageFile.readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(pdfImage));
            },
          ),
        );
      }

      final output = await getTemporaryDirectory();
      final file = File(
        "${output.path}/scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _selectedFile = file;
        _fileName =
            "Scanned_Doc_${DateTime.now().hour}_${DateTime.now().minute}.pdf";
      });
    }
  }

  Future<void> _uploadNote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please attach a file (PDF or Scan)")),
      );
      return;
    }

   
    try {
      int fileSizeInBytes = await _selectedFile!.length();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      if (fileSizeInMB > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "File too large (${fileSizeInMB.toStringAsFixed(2)}MB). Max 10MB allowed.",
            ),
          ),
        );
        return;
      }
    } catch (e) {
      print("Error checking file size: $e");
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      String finalSubject = getAvailableSubjects().isNotEmpty
          ? selectedSubject!
          : _subjectController.text.trim();

      // Use Backend for Verification & Drive Upload
      var uri = Uri.parse('https://api-gemini-notes.onrender.com/verify-note');

      var request = http.MultipartRequest('POST', uri);

      request.fields['subject'] = finalSubject;
      request.fields['module'] = selectedModule;

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Uploading to AI for Verification... Please wait."),
          duration: Duration(seconds: 2),
        ),
      );

      // Add timeout to the request
      var streamedResponse = await request.send().timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw Exception("Connection timed out. Please try again.");
        },
      );

      var responseData = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        var data = json.decode(responseData);
        String downloadUrl = data['url'];
        String status = data['status']; // 'approved', 'rejected', 'pending'
        String reason = data['reason'];
        String summary = data['summary'];

        Color snackColor = status == 'approved'
            ? Colors.green
            : (status == 'rejected' ? Colors.red : Colors.orange);
        String snackMsg = status == 'approved'
            ? "AI Approved! Note Published."
            : (status == 'rejected'
                  ? "AI Rejected: $reason"
                  : "AI Unsure. Sent for Admin Review.");

        await FirebaseFirestore.instance.collection('notes').add({
          'subject': finalSubject,
          'title': _titleController.text.trim(),
          'url': downloadUrl,
          'branch': selectedBranch,
          'semester': selectedSem,
          'module': selectedModule,
          'summary': summary,
          'createdAt': Timestamp.now(),
          'uploadedAt': Timestamp.now(),
          'status': status,
          'statusReason': reason,
          'verifiedBy': (status == 'approved' || status == 'rejected')
              ? 'AI'
              : null,
          'uploadedBy': user.uid,
          'uploaderName': user.displayName ?? "Unknown Student",
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackMsg),
            backgroundColor: snackColor,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      } else {
        String errorMsg = "Server Error: ${streamedResponse.statusCode}";
        try {
          var errorData = json.decode(responseData);
          if (errorData['error'] != null) {
            errorMsg = errorData['error'];
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableSubjects = getAvailableSubjects();

    return Scaffold(
      appBar: AppBar(title: Text("Upload Note")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: selectedBranch,
                items: branches
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedBranch = val!;
                    selectedSubject = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Branch",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedSem,
                items: semesters
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedSem = val!;
                    selectedSubject = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Semester",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              if (availableSubjects.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  isExpanded: true,
                  hint: Text("Select Subject"),
                  items: availableSubjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedSubject = val),
                  decoration: InputDecoration(
                    labelText: "Subject",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null ? "Required" : null,
                )
              else
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: "Subject Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedModule,
                items: modules
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => selectedModule = val!),
                decoration: InputDecoration(
                  labelText: "Module",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Note Title",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickPDF,
                      icon: Icon(Icons.upload_file),
                      label: Text("Pick PDF"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _scanAndCreatePDF,
                      icon: Icon(Icons.camera_alt),
                      label: Text("Scan Doc"),
                    ),
                  ),
                ],
              ),
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    "Selected: $_fileName",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),

              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Submit for Approval",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
