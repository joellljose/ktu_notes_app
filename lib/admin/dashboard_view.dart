import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardView extends StatefulWidget {
  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int totalUsers = 0;
  int totalNotes = 0;
  Map<String, int> branchDistribution = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      // 1. Count Users
      AggregateQuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .count()
          .get();
      totalUsers = userSnapshot.count ?? 0;

      // 2. Count Notes & Distribution
      QuerySnapshot notesSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .get(); // Note: Reads all docs. Optimize later if needed.

      totalNotes = notesSnapshot.docs.length;

      branchDistribution = {};
      for (var doc in notesSnapshot.docs) {
        String branch =
            (doc.data() as Map<String, dynamic>)['branch'] ?? 'Unknown';
        branchDistribution[branch] = (branchDistribution[branch] ?? 0) + 1;
      }
    } catch (e) {
      print("Error fetching stats: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dashboard Overview",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),

          // Stats Cards
          Row(
            children: [
              _buildStatCard(
                "Total Students",
                totalUsers.toString(),
                Icons.people,
                Colors.blue,
              ),
              SizedBox(width: 20),
              _buildStatCard(
                "Total Notes",
                totalNotes.toString(),
                Icons.library_books,
                Colors.green,
              ),
              SizedBox(width: 20),
              _buildStatCard(
                "Active Semesters",
                "8",
                Icons.school,
                Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 40),

          // Charts
          Text(
            "Notes Distribution by Branch",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: _generatePieSections(),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildLegend()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.cyan,
    ];
    int index = 0;

    return branchDistribution.entries.map((entry) {
      final isLarge = index == 0; // Highlight first
      final color = colors[index % colors.length];
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: isLarge ? 60 : 50,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.cyan,
    ];
    int index = 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: branchDistribution.entries.map((entry) {
        final color = colors[index % colors.length];
        index++;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: color),
              SizedBox(width: 8),
              Text("${entry.key}: ${entry.value} notes"),
            ],
          ),
        );
      }).toList(),
    );
  }
}
