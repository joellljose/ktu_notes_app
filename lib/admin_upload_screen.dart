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
  String? selectedSubject; 

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
    'Civil': {
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
        'Mechanics Of Solids - (CET201)',
        'Fluid Mechanics & Hydraulics - (CET203)',
        'Surveying & Geomatics - (CET205)',
        'Design And Engineering - (EST200)',
        'Professional Ethics - (HUT200)',
        'Sustainable Engineering - (MCN201)',
        'Civil Engineering Planning & Drafting Lab - (CEL201)',
        'Survey Lab - (CEL203)',
      ],
      'S4': [
        'Probability, Statistics And Numerical Methods - (MAT202)',
        'Engineering Geology - (CET202)',
        'Geotechnical Engineering - I - (CET204)',
        'Transportation Engineering - (CET206)',
        'Design And Engineering - (EST200)',
        'Professional Ethics - (HUT200)',
        'Constitution Of India - (MCN202)',
        'Material Testing Lab - I - (CEL202)',
        'Fluid Mechanics Lab - (CEL204)',
      ],
      'S5': [
        'Structural Analysis – I - (CET301)',
        'Design Of Concrete Structures - (CET303)',
        'Geotechnical Engineering – II - (CET305)',
        'Hydrology & Water Resources Engineering - (CET307)',
        'Construction Technology & Management - (CET309)',
        'Disaster Management - (MCN301)',
        'Material Testing Lab – II - (CEL331)',
        'Geotechnical Engineering Lab - (CEL333)',
      ],
      'S6': [
        'Structural Analysis – II - (CET302)',
        'Environmental Engineering - (CET304)',
        'Design Of Hydraulic Structures - (CET306)',
        'Industrial Economics And Foreign Trade - (HUT300)',
        'Comrehensive Course Work - (CET308)',
        'Transportation Engineering Lab - (CEL332)',
        'Civil Engineering Software Lab - (CEL334)',
      ],
      'S7': [
        'Design Of Steel Structures - (CET401)',
        'Industrial Safety Engineering - (MCN401)',
        'Environmental Engg Lab - (CEL411)',
        'Seminar - (CEQ413)',
        'Project Phase I - (CED415)',
      ],
      'S8': [
        'Quantity Surveying & Valuation - (CET402)',
        'Comprehensive Viva Voce - (CET404)',
        'Project Phase II - (CED416)',
      ],
    },
    'Electrical': {
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
        'Circuits And Networks - (EET201)',
        'Measurements And Instrumentation - (EET203)',
        'Analog Electronics - (EET205)',
        'Design And Engineering - (EST200)',
        'Professional Ethics - (HUT200)',
        'Sustainable Engineering - (MCN201)',
        'Circuits And Measurements Lab - (EEL201)',
        'Analog Electronics Lab - (EEL203)',
      ],
      'S4': [
        'Probability, Random Processes And Numerical Methods - (MAT204)',
        'DC Machines And Transformers - (EET202)',
        'Electromagnetic Theory - (EET204)',
        'Digital Electronics - (EET206)',
        'Design And Engineering - (EST200)',
        'Professional Ethics - (HUT200)',
        'Constitution Of India - (MCN202)',
        'Electrical Machines Lab I - (EEL202)',
        'Digital Electronics Lab - (EEL204)',
      ],
      'S5': [
        'Power Systems I - (EET301)',
        'Microprocessors And Microcontrollers - (EET303)',
        'Signals And Systems - (EET305)',
        'Synchronous And Induction Machines - (EET307)',
        'Industrial Economics And Foreign Trade - (HUT300)',
        'Management For Engineers - (HUT310)',
        'Disaster Management - (MCN301)',
        'Microprocessors And Microcontrollers Lab - (EEL331)',
        'Electrical Machines Lab II - (EEL333)',
      ],
      'S6': [
        'Linear Control Systems - (EET302)',
        'Power Systems II - (EET304)',
        'Power Electronics - (EET306)',
        'Industrial Economics And Foreign Trade - (HUT300)',
        'Management For Engineers - (HUT310)',
        'Comrehensive Course Work - (EET308)',
        'Power Systems Lab - (EEL332)',
        'Power Electronics Lab - (EEL334)',
      ],
      'S7': [
        'Advanced Control Systems - (EET401)',
        'Industrial Safety Engineering - (MCN401)',
        'Control Systems Lab - (EEL411)',
        'Seminar - (EEQ413)',
        'Project Phase I - (EED415)',
      ],
      'S8': [
        'Electrical System Design And Estimation - (EET402)',
        'Comprehensive Course Viva - (EET404)',
        'Project Phase II - (EED416)',
      ],
    },
    'Electronics': {
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
        'Solid State Devices - (ECT201)',
        'Logic Circuit Design - (ECT203)',
        'Network Theory - (ECT205)',
        'Design And Engineering - (EST200)',
        'Professional Ethics - (HUT200)',
        'Sustainable Engineering - (MCN201)',
        'Scientific Computing Lab - (ECL201)',
        'Logic Design Lab - (ECL203)',
      ],
      'S4': [
        'Probability, Random Processes And Numerical Methods - (MAT204)',
        'Analog Circuits - (ECT202)',
        'Signals And Systems - (ECT204)',
        'Computer Architecture And Microcontrollers - (ECT206)',
        'Design And Engineering - (EST200)',
        'Professional Ethics - (HUT200)',
        'Constitution Of India - (MCN202)',
        'Analog Circuits And Simulation Lab - (ECL202)',
        'Microcontroller Lab - (ECL204)',
      ],
      'S5': [
        'Linear Integrated Circuits - (ECT301)',
        'Digital Signal Processing - (ECT303)',
        'Analog And Digital Communication - (ECT305)',
        'Control Systems - (ECT307)',
        'Industrial Economics And Foreign Trade - (HUT300)',
        'Management For Engineers - (HUT310)',
        'Disaster Management - (MCN301)',
        'Analog Integrated Circuits And Simulation Lab - (ECL331)',
        'Digital Signal Processing Lab - (ECL333)',
      ],
      'S6': [
        'Electromagnetics - (ECT302)',
        'VlSI Circuit Design - (ECT304)',
        'Information Theory And Coding - (ECT306)',
        'Industrial Economics And Foreign Trade - (HUT300)',
        'Management For Engineers - (HUT310)',
        'Comprehensive Course Work - (ECT308)',
        'Communication Lab - (ECL332)',
        'Miniproject - (ECD334)',
      ],
      'S7': [
        'Wireless Communication - (ECT401)',
        'Industrial Safety Engineering - (MCN401)',
        'Electromagnetics Lab - (ECL411)',
        'Seminar - (ECQ413)',
        'Project Phase I - (ECD415)',
      ],
      'S8': [
        'Instrumentation - (ECT402)',
        'Comprehensive Viva Voce - (ECT404)',
        'Project Phase II - (ECD416)',
      ],
    },
  };

  
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
                          selectedSubject = null; 
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
                          selectedSubject = null; 
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
                      'uploadedAt':
                          Timestamp.now(), 
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
