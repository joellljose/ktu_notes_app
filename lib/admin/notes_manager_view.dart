import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_config.dart';

class NotesManagerView extends StatefulWidget {
  @override
  _NotesManagerViewState createState() => _NotesManagerViewState();
}

class _NotesManagerViewState extends State<NotesManagerView> {
  String? selectedBranch;
  String? selectedSem;

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Manage Notes",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TabBar(
              labelColor: Colors.purple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.purple,
              tabs: [
                Tab(text: "Approved Notes"),
                Tab(text: "Pending Requests"),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNotesList(isPending: false),
                  _buildNotesList(isPending: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList({required bool isPending}) {
    Query query = FirebaseFirestore.instance
        .collection('notes')
        .orderBy('uploadedAt', descending: true);

    if (isPending) {
      query = query.where('status', isEqualTo: 'pending');
    } else {
      // For approved list, we want approved OR legacy (null status)
      // But we can't do OR query easily with multiple conditions.
      // So we'll fetch all and filter in client (like in notes_list_screen) OR just fetch everything that is NOT pending?
      // "Not equals" is also tricky with ordering.
      // Let's rely on client side filtering for "Approved" tab to be consistent with legacy data.
      // Or better: filter where 'status' is not equal to 'pending' if possible? No.
      // Let's just fetch all and filter locally for simplicity given the data scale.
    }

    if (selectedBranch != null) {
      query = query.where('branch', isEqualTo: selectedBranch);
    }
    if (selectedSem != null) {
      query = query.where('semester', isEqualTo: selectedSem);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No notes found."));
        }

        var docs = snapshot.data!.docs;

        // Client side filtering for correct tab content
        var filteredDocs = docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String? status = data['status'];
          if (isPending) {
            return status == 'pending';
          } else {
            // Approved tab: Show if approved OR legacy (null)
            return status == 'approved' || status == null;
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              isPending ? "No pending requests." : "No notes uploaded.",
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    "Subject",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Title",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Branch",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Sem",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Status",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Actions",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: filteredDocs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(Text(data['subject'] ?? 'N/A')),
                    DataCell(Text(data['title'] ?? 'N/A')),
                    DataCell(Text(data['branch'] ?? 'N/A')),
                    DataCell(Text(data['semester'] ?? 'N/A')),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPending
                              ? Colors.orange[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPending ? "Pending" : "Approved",
                          style: TextStyle(
                            color: isPending
                                ? Colors.orange[900]
                                : Colors.green[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.download, color: Colors.blue),
                            onPressed: () => _launchURL(data['url']),
                            tooltip: "View PDF",
                          ),
                          if (isPending) ...[
                            IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () =>
                                  _updateStatus(doc.id, 'approved'),
                              tooltip: "Approve",
                            ),
                            IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () =>
                                  _updateStatus(doc.id, 'rejected'),
                              tooltip: "Reject",
                            ),
                          ] else
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteNote(context, doc.id),
                              tooltip: "Delete",
                            ),
                          if (!isPending)
                            IconButton(
                              icon: Icon(
                                Icons.auto_awesome,
                                color: Colors.purple,
                              ),
                              onPressed: () => _generateAISummary(
                                context,
                                doc.id,
                                data['url'],
                              ),
                              tooltip: "Generate AI Summary",
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('notes').doc(docId).update({
        'status': status,
        'verifiedBy': 'Admin',
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Note $status")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _generateAISummary(
    BuildContext context,
    String docId,
    String url,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Generating AI Summary... Please wait.")),
    );

    try {
      // Use 10.0.2.2 for emulator, localhost or IP for web/device
      var uri = Uri.parse(
        ApiConfig.generateSummary,
      );
      var response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"url": url}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String summary = data['summary'];

        await FirebaseFirestore.instance.collection('notes').doc(docId).update({
          'summary': summary,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("AI Summary Updated Successfully!")),
        );
      } else {
        throw Exception("Failed to generate summary: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _launchURL(String? url) async {
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _deleteNote(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Note"),
        content: Text(
          "Are you sure you want to delete this note? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('notes')
                  .doc(docId)
                  .delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Note Deleted")));
            },
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
