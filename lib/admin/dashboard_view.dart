import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notes')
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text("Error: ${snapshot.error}");
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          int totalNotes = docs.length;

          // Calculate Branch Distribution
          Map<String, int> branchDist = {};
          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            String b = data['branch'] ?? 'Unknown';
            branchDist[b] = (branchDist[b] ?? 0) + 1;
          }

          // Calculate Activity (Notes per Day for last 7 entries or simulated)
          // For a "movement" feel, we'll plot the indices of recent uploads or time gaps
          // A real production app would aggregate this server-side or cleaner.
          // Here we plot "Number of uploads per day" for the available data.
          Map<String, int> activityMap = {};
          for (var doc in docs) {
            // Assuming uploadedAt exists, if not use current time as fallback for display (mock)
            // In real app, ensure 'uploadedAt' is set.
            // We will check if field exists.
            var data = doc.data() as Map<String, dynamic>;
            if (data['uploadedAt'] != null) {
              DateTime date = (data['uploadedAt'] as Timestamp).toDate();
              String key = DateFormat('MM-dd').format(date);
              activityMap[key] = (activityMap[key] ?? 0) + 1;
            }
          }

          // Sort activity for chart
          var sortedKeys = activityMap.keys.toList()..sort();
          // Take last 7 days
          if (sortedKeys.length > 7)
            sortedKeys = sortedKeys.sublist(sortedKeys.length - 7);

          List<FlSpot> spots = [];
          for (int i = 0; i < sortedKeys.length; i++) {
            spots.add(
              FlSpot(i.toDouble(), activityMap[sortedKeys[i]]!.toDouble()),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 800;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Live Overview",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),

                  // 1. TOP SECTION: Counters
                  if (isMobile)
                    Column(
                      children: [
                        Container(height: 100, child: _UserCounterCard()),
                        SizedBox(height: 15),
                        Container(height: 100, child: _OnlineUserCounterCard()),
                        SizedBox(height: 15),
                        Container(height: 100, child: _ClickCounterCard()),
                        SizedBox(height: 15),
                        Container(
                          height: 100,
                          child: _buildStatCard(
                            "Live Notes",
                            totalNotes.toString(),
                            Icons.library_books,
                            Colors.green,
                          ),
                        ),
                        SizedBox(height: 15),
                        Container(
                          height: 100,
                          child: _buildStatCard(
                            "Active Branches",
                            branchDist.keys.length.toString(),
                            Icons.category,
                            Colors.orange,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: _UserCounterCard()),
                        SizedBox(width: 20),
                        Expanded(child: _OnlineUserCounterCard()),
                        SizedBox(width: 20),
                        Expanded(child: _ClickCounterCard()),
                        SizedBox(width: 20),
                        _buildStatCard(
                          "Live Notes",
                          totalNotes.toString(),
                          Icons.library_books,
                          Colors.green,
                        ),
                        SizedBox(width: 20),
                        _buildStatCard(
                          "Active Branches",
                          branchDist.keys.length.toString(),
                          Icons.category,
                          Colors.orange,
                        ),
                      ],
                    ),
                  SizedBox(height: 30),

                  // 2. MIDDLE SECTION: Charts
                  if (isMobile)
                    Column(
                      children: [
                        Container(
                          height: 300,
                          child: _buildChartContainer(
                            "Upload Activity (Last 7 Days)",
                            LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, meta) {
                                        int index = val.toInt();
                                        if (index >= 0 &&
                                            index < sortedKeys.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Text(
                                              sortedKeys[index],
                                              style: TextStyle(fontSize: 10),
                                            ),
                                          );
                                        }
                                        return Text('');
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.black12),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots.isEmpty
                                        ? [FlSpot(0, 0)]
                                        : spots,
                                    isCurved: true,
                                    color: Colors.blueAccent,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.blueAccent.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          height: 300,
                          child: _buildChartContainer(
                            "Branch Distribution",
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 30,
                                sections: _generatePieSections(branchDist),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      height: 300,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildChartContainer(
                              "Upload Activity (Last 7 Days)",
                              LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          int index = val.toInt();
                                          if (index >= 0 &&
                                              index < sortedKeys.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                sortedKeys[index],
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            );
                                          }
                                          return Text('');
                                        },
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots.isEmpty
                                          ? [FlSpot(0, 0)]
                                          : spots,
                                      isCurved: true,
                                      color: Colors.blueAccent,
                                      barWidth: 3,
                                      dotData: FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.blueAccent.withOpacity(
                                          0.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            flex: 1,
                            child: _buildChartContainer(
                              "Branch Distribution",
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 30,
                                  sections: _generatePieSections(branchDist),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 30),

                  // 3. BOTTOM ROW: Live Terminal
                  Text(
                    "System Terminal /// Live Feed",
                    style: GoogleFonts.firaCode(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 200,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E1E2C), // Terminal Black
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      itemCount: docs.length > 20
                          ? 20
                          : docs.length, // Show last 20 logs
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        String subject = data['subject'] ?? 'Unknown Subject';
                        String branch = data['branch'] ?? 'Unknown Branch';
                        // Attempt to format time
                        String timeStr = "Just now";
                        if (data['uploadedAt'] != null) {
                          timeStr = DateFormat(
                            'HH:mm:ss',
                          ).format((data['uploadedAt'] as Timestamp).toDate());
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text(
                                "[$timeStr] ",
                                style: GoogleFonts.firaCode(
                                  color: Colors.greenAccent,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "UPLOAD: ",
                                style: GoogleFonts.firaCode(
                                  color: Colors.yellowAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "$subject to $branch",
                                  style: GoogleFonts.firaCode(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 15),
          Expanded(child: chart),
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
        height: 100,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    value,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(Map<String, int> branchDist) {
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.cyan,
    ];
    int index = 0;

    return branchDist.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}

class _UserCounterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        String count = snapshot.hasData
            ? snapshot.data!.docs.length.toString()
            : "...";
        return Container(
          height: 100,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(Icons.people, color: Colors.blue),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Total Students",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      count,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnlineUserCounterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        String count = "...";
        if (snapshot.hasData) {
          final now = DateTime.now();
          final activeUsers = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['lastActive'] == null) return false;
            final lastActive = (data['lastActive'] as Timestamp).toDate();
            // Active within last 7 minutes
            return now.difference(lastActive).inMinutes < 7;
          }).length;
          count = activeUsers.toString();
        }

        return Container(
          height: 100,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal.withOpacity(0.1),
                child: Icon(Icons.circle, color: Colors.teal, size: 14),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Online Users",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      count,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClickCounterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stats')
          .doc('activity')
          .snapshots(),
      builder: (context, snapshot) {
        String count = "...";
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          count = (data['totalClicks'] ?? 0).toString();
        } else if (snapshot.hasData && !snapshot.data!.exists) {
          count = "0";
        }

        return Container(
          height: 100,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purple.withOpacity(0.1),
                child: Icon(Icons.touch_app, color: Colors.purple),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Total Clicks",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      count,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
