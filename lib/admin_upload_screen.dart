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
  String? selectedSubject; // For Dropdown

  List<String> branches = [
    'Computer Science',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
    'Common',
  ];
  List<String> semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  List<String> modules = [
    'Module 1',
    'Module 2',
    'Module 3',
    'Module 4',
    'Module 5',
    'Module 6',
  ];

  // Data for Auto-Population
  Map<String, Map<String, List<String>>> get courseData => {
    'Computer Science': {
      'S1': [
        'Linear Algebra And Calculus - (MAT101)',
        'Engineering Physics A - (PHT100)',
        'Engineering Chemistry - (CYT100)',
        'Engineering Mechanics - (EST100)',
        'Engineering Graphics - (EST110)',
        'Basics Of Civil & Mechanical Engineering - (EST120)',
        'Basics Of Electrical & Electronics Engineering - (EST130)',
        'Life Skills - (HUN101)',
      ],
      'S2': [
        'Vector Calculus, Differential Equations And Transforms - (MAT102)',
        'Engineering Physics A - (PHT100)',
        'Engineering Chemistry - (CYT100)',
        'Engineering Mechanics - (EST100)',
        'Engineering Graphics - (EST110)',
        'Basics Of Civil & Mechanical Engineering - (EST120)',
        'Basics Of Electrical & Electronics Engineering - (EST130)',
        'Professional Communication - (HUN102)',
        'Programming In C - (EST102)',
      ],
      'S3': [
        'Discrete Mathematical Structures - (MAT203)',
        'Data Structures - (CST201)',
        'Logic System Design - (CST203)',
        'Object Oriented Programming Using Java - (CST205)',
        'Design And Engineering - (EST200)',
        'Professional Ethics - (HUT200)',
        'Sustainable Engineering - (MCN201)',
      ],
      'S4': [
        'Graph Theory - (MAT206)',
        'Computer Organisation And Architecture - (CST202)',
        'Database Management Systems - (CST204)',
        'Operating Systems - (CST206)',
        'Design And Engineering - (EST200)',
        'Professional Ethics - (HUT200)',
        'Constitution Of India - (MCN202)',
      ],
      'S5': [
        'Formal Languages And Automata Theory - (CST301)',
        'Computer Networks - (CST303)',
        'System Software - (CST305)',
        'Microprocessors And Microcontrollers - (CST307)',
        'Management Of Software Systems - (CST309)',
        'Disaster Management - (MCN301)',
      ],
      'S6': [
        'Compiler Design - (CST302)',
        'Computer Graphics And Image Processing - (CST304)',
        'Algorithm Analysis And Design - (CST306)',
        'Industrial Economics And Foreign Trade - (HUT300)',
        'Comprehensive Course Work - (CST308)',
      ],
      'S7': [
        'Artificial Intelligence - (CST401)',
        'Industrial Safety Engineering - (MCN401)',
        'Seminar - (CSQ413)',
        'Project Phase I - (CSD415)',
      ],
      'S8': [
        'Distributed Computing - (CST402)',
        'Comprehensive Course Viva - (CST404)',
        'Project Phase II - (CSD416)',
      ],
    },
    'Mechanical': {
      'S1': [
        'Linear Algebra And Calculus - (MAT101)',
        'Engineering Physics A - (PHT100)',
        'Engineering Chemistry - (CYT100)',
        'Engineering Mechanics - (EST100)',
        'Engineering Graphics - (EST110)',
        'Basics Of Civil & Mechanical Engineering - (EST120)',
        'Basics Of Electrical & Electronics Engineering - (EST130)',
        'Life Skills - (HUN101)',
        'Engineering Physics Lab - (PHL120)',
        'Engineering Chemistry Lab - (CYL120)',
        'Civil & Mechanical Workshop - (ESL120)',
        'Electrical & Electronics Workshop - (ESL130)',
      ],
      'S2': [
        'Vector Calculus, Differential Equations And Transforms - (MAT102)',
        'Engineering Physics A - (PHT100)',
        'Engineering Chemistry - (CYT100)',
        'Engineering Mechanics - (EST100)',
        'Engineering Graphics - (EST110)',
        'Basics Of Civil & Mechanical Engineering - (EST120)',
        'Basics Of Electrical & Electronics Engineering - (EST130)',
        'Professional Communication - (HUN102)',
        'Programming In C - (EST102)',
        'Engineering Physics Lab - (PHL120)',
        'Engineering Chemistry Lab - (CYL120)',
        'Civil & Mechanical Workshop - (ESL120)',
        'Electrical & Electronics Workshop - (ESL130)',
      ],
      'S3': [
        'Partial Differential Equation And Complex Analysis - (MAT201)',
        'Mechanics Of Solids - (MET201)',
        'Mechanics Of Fluids - (MET203)',
        'Metallurgy & Material Science - (MET205)',
        'Design And Engineering - (EST200)',
        'Professional Ethics - (HUT200)',
        'Sustainable Engineering - (MCN201)',
        'Computer Aided Machine Drawing - (MEL201)',
        'Materials Testing Lab - (MEL203)',
      ],
      'S4': [
        'Probability, Statistics And Numerical Methods - (MAT202)',
        'Engineering Thermodynamics - (MET202)',
        'Manufacturing Process - (MET204)',
        'Fluid Machinery - (MET206)',
        'Design And Engineering - (EST200)',
        'Professional Ethics - (HUT200)',
        'Constitution Of India - (MCN202)',
        'Fm & Hm Lab - (MEL202)',
        'Machine Tools Lab-I - (MEL204)',
      ],
      'S5': [
        'Mechanics Of Machinery - (MET301)',
        'Thermal Engineering - (MET303)',
        'Industrial & Systems Engineering - (MET305)',
        'Machine Tools And Metrology - (MET307)',
        'Industrial Economics And Foreign Trade - (HUT300)',
        'Management For Engineers - (HUT310)',
        'Disaster Management - (MCN301)',
        'Machine Tools Lab-II - (MEL331)',
        'Thermal Engineering Lab-I - (MEL333)',
      ],
      'S6': [
        'Heat & Mass Transfer - (MET302)',
        'Dynamics Of Machinery & Machine Design - (MET304)',
        'Advanced Manufacturing Engineering - (MET306)',
        'Industrial Economics And Foreign Trade - (HUT300)',
        'Management For Engineers - (HUT310)',
        'Comprehensive Course Work - (MET308)',
        'Computer Aided Design & Analysis Lab - (MEL332)',
        'Thermal Engineering Lab-Ii - (MEL334)',
      ],
      'S7': [
        'Design Of Machine Elements - (MET401)',
        'Industrial Safety Engineering - (MCN401)',
        'Mechanical Engineering Lab - (MEL411)',
        'Seminar - (MEQ413)',
        'Project Phase I - (MED415)',
      ],
      'S8': [
        'Mechatronics - (MET402)',
        'Comprehensive Viva Voce - (MET404)',
        'Project Phase II - (MED416)',
      ],
    },
  };

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

  List<String> getAvailableSubjects() {
    if (courseData.containsKey(selectedBranch) &&
        courseData[selectedBranch]!.containsKey(selectedSem)) {
      return courseData[selectedBranch]![selectedSem]!;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableSubjects = getAvailableSubjects();

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
              // Branch & Sem Selectors FIRST so Subject can update
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedBranch,
                      items: branches
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(b, style: TextStyle(fontSize: 12)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedBranch = val as String;
                          selectedSubject = null; // Reset subject on change
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Branch",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedSem,
                      items: semesters
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSem = val as String;
                          selectedSubject = null; // Reset subject on change
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Sem",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              // CONDITIONAL SUBJECT INPUT
              if (availableSubjects.isNotEmpty)
                DropdownButtonFormField(
                  value: selectedSubject,
                  hint: Text("Select Subject"),
                  isExpanded: true,
                  items: availableSubjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedSubject = val as String),
                  decoration: InputDecoration(
                    labelText: "Subject",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null ? "Select a subject" : null,
                )
              else
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: "Subject Name (Manual Entry)",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
              SizedBox(height: 15),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Note Title (e.g. Module 1 Part A)",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: "Paste Google Drive Link",
                  hintText: "https://drive.google.com/file/d/...",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 15),

              DropdownButtonFormField(
                value: selectedModule,
                items: modules
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => selectedModule = val as String),
                decoration: InputDecoration(
                  labelText: "Module",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _summaryController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "AI Summary",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String directUrl = convertToDirectLink(
                      _urlController.text.trim(),
                    );

                    // Use Dropdown value OR Text Controller value
                    String finalSubject = availableSubjects.isNotEmpty
                        ? selectedSubject!
                        : _subjectController.text.trim();

                    await FirebaseFirestore.instance.collection('notes').add({
                      'subject': finalSubject,
                      'title': _titleController.text.trim(),
                      'url': directUrl,
                      'branch': selectedBranch,
                      'semester': selectedSem,
                      'module': selectedModule,
                      'summary': _summaryController.text.trim(),
                      'createdAt': Timestamp.now(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Note published successfully!")),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  "PUBLISH NOTE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
