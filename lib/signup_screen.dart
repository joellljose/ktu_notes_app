import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String selectedBranch = 'Computer Science';
  String selectedSem = 'S1';

  List<String> branches = [
    'Computer Science',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
  ];
  List<String> semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Student Registration")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Enter email" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.length < 6 ? "Min 6 characters" : null,
              ),
              SizedBox(height: 15),

              // Branch Dropdown
              DropdownButtonFormField(
                value: selectedBranch,
                decoration: InputDecoration(
                  labelText: "Select Branch",
                  border: OutlineInputBorder(),
                ),
                items: branches
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => selectedBranch = val as String),
              ),
              SizedBox(height: 15),

              // Semester Dropdown
              DropdownButtonFormField(
                value: selectedSem,
                decoration: InputDecoration(
                  labelText: "Select Semester",
                  border: OutlineInputBorder(),
                ),
                items: semesters
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => selectedSem = val as String),
              ),
              SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      UserCredential result = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );

                      // 2. Save Profile to Firestore
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(result.user!.uid)
                          .set({
                            'uid': result.user!.uid,
                            'email': _emailController.text.trim(),
                            'branch': selectedBranch,
                            'semester': selectedSem,
                            'role': 'student',
                          });

                      Navigator.pop(context);
                    } catch (e) {
                      print(e);
                    }
                  }
                },
                child: Text("REGISTER"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
