import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // For themeNotifier

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool isSaving = false;

  String? selectedBranch;
  String? selectedSem;

  List<String> branches = [
    'Computer Science',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
    'Common',
  ];
  List<String> semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Profile"), backgroundColor: Colors.teal),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || !snapshot.data!.exists)
            return Center(child: Text("Error loading profile"));

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          
          selectedBranch ??= userData['branch'];
          selectedSem ??= userData['semester'];

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    userData['email'],
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 30),

                  
                  DropdownButtonFormField(
                    value: selectedBranch,
                    decoration: InputDecoration(
                      labelText: "Current Branch",
                      border: OutlineInputBorder(),
                    ),
                    items: branches
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedBranch = val as String),
                  ),
                  SizedBox(height: 20),

                  
                  DropdownButtonFormField(
                    value: selectedSem,
                    decoration: InputDecoration(
                      labelText: "Current Semester",
                      border: OutlineInputBorder(),
                    ),
                    items: semesters
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedSem = val as String),
                  ),
                  SizedBox(height: 30),

                  // Dark Mode Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: SwitchListTile(
                      title: Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w600)),
                      secondary: Icon(
                          themeNotifier.value == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                          color: themeNotifier.value == ThemeMode.dark ? Colors.amber : Colors.orange,
                      ),
                      value: themeNotifier.value == ThemeMode.dark,
                      activeColor: Colors.teal,
                      onChanged: (bool value) {
                        setState(() {
                          themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                        });
                      },
                    ),
                  ),
                  if (userData['isSubscribed'] == true && userData['subscriptionExpiry'] != null)
                    _buildSubscriptionDetails(userData),
                  SizedBox(height: 40),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            setState(() => isSaving = true);
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user!.uid)
                                .update({
                                  'branch': selectedBranch,
                                  'semester': selectedSem,
                                });
                            setState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Profile Updated!")),
                            );
                            Navigator.pop(context); 
                          },
                    child: isSaving
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "SAVE CHANGES",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionDetails(Map<String, dynamic> userData) {
    Timestamp? expiry = userData['subscriptionExpiry'];
    Timestamp? start = userData['subscriptionStartDate'];
    bool isExpired = expiry != null && DateTime.now().isAfter(expiry.toDate());

    return Container(
      margin: EdgeInsets.only(top: 30),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isExpired ? Colors.orange.shade50 : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpired ? Colors.orange.shade200 : Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: isExpired ? Colors.orange : Colors.teal, size: 28),
              SizedBox(width: 10),
              Text(
                "Subscription Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.orange.shade900 : Colors.teal.shade900,
                ),
              ),
            ],
          ),
          Divider(height: 24),
          _detailRow("Status:", isExpired ? "Expired" : "Active", isExpired ? Colors.red : Colors.green),
          if (start != null)
            _detailRow("Start Date:", _formatDate(start)),
          if (expiry != null)
            _detailRow("Valid Until:", _formatDate(expiry)),
          if (userData['amountPaid'] != null)
            _detailRow("Amount Paid:", "₹\${userData['amountPaid']}"),
          if (userData['paymentId'] != null)
            _detailRow("Payment ID:", userData['paymentId'].toString(), Colors.grey.shade600, 12),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, [Color? valueColor, double? fontSize]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "\${date.day} \${months[date.month - 1]} \${date.year}";
  }
}
