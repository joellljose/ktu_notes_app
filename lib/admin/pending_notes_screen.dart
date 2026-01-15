import 'package:ai_ktu_notes_app/data/course_data.dart' as course_data;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PendingNotesScreen extends StatefulWidget {
  @override
  _PendingNotesScreenState createState() => _PendingNotesScreenState();
}

class _PendingNotesScreenState extends State<PendingNotesScreen> {
  // Store pending items: Map of Branch -> List of "Subject - Module" strings
  Map<String, List<String>> pendingItems = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingNotes();
  }

  Future<void> _fetchPendingNotes() async {
    setState(() => isLoading = true);

    Map<String, List<String>> tempPending = {};

    try {
      // 1. Fetch ALL notes once to minimize reads (optimize this in production with aggregations if possible)
      // For now, fetching all documents ID/metadata might be heavy if thousands of notes.
      // But we need to know WHICH modules are missing.
      // Optimization: We could store a 'note_counts' collection separately.
      // For this implementation, we'll fetch basic fields.
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notes')
          // .select(['subject', 'module', 'branch']) // Client SDK doesn't support select() easily
          .get();

      // Create a Set of existing "Subject|Module" keys for fast lookup
      Set<String> existingNotes = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String subject = data['subject'] ?? "";
        String module = data['module'] ?? "";
        if (subject.isNotEmpty && module.isNotEmpty) {
          existingNotes.add("$subject|$module");
        }
      }

      // 2. Iterate through our static course data
      var allData = course_data.courseData;

      // Structure: Branch -> Sem -> List<Subject>
      allData.forEach((branch, semesters) {
        if (!tempPending.containsKey(branch)) {
          tempPending[branch] = [];
        }

        semesters.forEach((sem, subjects) {
          for (String subjectFull in subjects) {
            // Check all 5 modules
            for (int i = 1; i <= 5; i++) {
              String moduleName = "Module $i";
              String key = "$subjectFull|$moduleName";

              if (!existingNotes.contains(key)) {
                // This specific module for this subject has NO notes
                tempPending[branch]!.add("$subjectFull - $moduleName ($sem)");
              }
            }
          }
        });
      });

      setState(() {
        pendingItems = tempPending;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching pending notes: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (pendingItems.isEmpty ||
        pendingItems.values.every((list) => list.isEmpty)) {
      return Center(child: Text("Amazing! No pending notes found."));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Pending Notes"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchPendingNotes),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: pendingItems.keys.length,
        itemBuilder: (context, index) {
          String branch = pendingItems.keys.elementAt(index);
          List<String> items = pendingItems[branch] ?? [];

          if (items.isEmpty) return SizedBox.shrink();

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                "$branch (${items.length} Pending)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: items
                  .map(
                    (item) => ListTile(
                      leading: Icon(Icons.warning, color: Colors.orange),
                      title: Text(item, style: TextStyle(fontSize: 13)),
                      dense: true,
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
