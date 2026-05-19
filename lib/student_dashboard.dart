import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'module_list_screen.dart';
import 'admin_upload_screen.dart';
import 'profile_screen.dart';
import 'community_chat_screen.dart';
import 'notification_history_screen.dart';
import 'student_upload_screen.dart';
import 'topic_insights_screen.dart';
import 'smart_search_screen.dart';
import 'code_explainer_screen.dart';
import 'ai_diagram_screen.dart';
import 'ai_doubt_chatbot_screen.dart';
import 'note_detail_screen.dart';
import 'favorites_screen.dart';
import 'ai_summarizer_screen.dart';
import 'subscription_screen.dart';
class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null)
      return Scaffold(body: const Center(child: Text("Not Logged In")));

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminUploadScreen()),
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Entering Admin Mode...")));
          },
          child: const Text("KTU Subjects"),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SmartSearchScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.account_circle, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    user.email ?? "Student",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("My Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications, size: 20),
              title: Text("Notifications"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationHistoryScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite, size: 20, color: Colors.redAccent),
              title: Text("My Favorites"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.stars, size: 20, color: Colors.orange),
              title: Text("Subscription Details"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError ||
              !userSnapshot.hasData ||
              !userSnapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Profile Error. Please check your connection."),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            );
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String branch = userData['branch'] ?? "Not Set";
          String semester = userData['semester'] ?? "Not Set";
          bool isSubscribed = userData['isSubscribed'] ?? false;
          if (isSubscribed && userData['subscriptionExpiry'] != null) {
            Timestamp expiry = userData['subscriptionExpiry'];
            if (DateTime.now().isAfter(expiry.toDate())) {
              isSubscribed = false;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Branch/Sem info
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  border: Border(bottom: BorderSide(color: Colors.teal.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.teal, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "$semester | $branch",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // AI Toolkit Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  "AI Discovery Tools",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                ),
              ),
              
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildToolCard(
                      context, 
                      "Summarizer", 
                      Icons.summarize_outlined, 
                      Colors.teal,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => AiSummarizerScreen())),
                      isPremiumOnly: true,
                      isSubscribed: isSubscribed,
                    ),
                    _buildToolCard(
                      context, 
                      "Smart Search", 
                      Icons.search, 
                      Colors.teal,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => SmartSearchScreen())),
                      isPremiumOnly: true,
                      isSubscribed: isSubscribed,
                    ),
                    _buildToolCard(
                      context, 
                      "Doubt Chat", 
                      Icons.psychology_alt, 
                      Colors.indigo,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => AiDoubtChatbotScreen(branch: branch, semester: semester))),
                      isPremiumOnly: true,
                      isSubscribed: isSubscribed,
                    ),
                    _buildToolCard(
                      context, 
                      "Diagrams", 
                      Icons.schema_outlined, 
                      Colors.blue,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => AiDiagramScreen())),
                      isPremiumOnly: true,
                      isSubscribed: isSubscribed,
                    ),
                    _buildToolCard(
                      context, 
                      "Insights", 
                      Icons.lightbulb_outline, 
                      Colors.orange,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => TopicInsightsScreen())),
                      isPremiumOnly: true,
                      isSubscribed: isSubscribed,
                    ),
                    _buildToolCard(
                      context, 
                      "Class Chat", 
                      Icons.chat_bubble_outline, 
                      Colors.teal,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityChatScreen(branch: branch, semester: semester))),
                    ),
                    if (branch == 'Computer Science')
                      _buildToolCard(
                        context, 
                        "Explainer", 
                        Icons.code, 
                        Colors.deepPurple,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => CodeExplainerScreen())),
                        isPremiumOnly: true,
                        isSubscribed: isSubscribed,
                      ),
                  ],
                ),
              ),

              // Saved Notes Section (Horizontal Scroll)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('favorites')
                    .orderBy('timestamp', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, favSnapshot) {
                  if (!favSnapshot.hasData || favSnapshot.data!.docs.isEmpty) {
                    return SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Saved Notes ❤️",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
                              },
                              child: const Text("VIEW ALL", style: TextStyle(fontSize: 12, color: Colors.teal)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          itemCount: favSnapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var data = favSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (context) => NoteDetailScreen(
                                      title: data['title'] ?? 'Note',
                                      pdfUrl: data['pdfUrl'] ?? '',
                                      summary: data['summary'] ?? '',
                                    )
                                  )
                                );
                              },
                              child: Container(
                                width: 140,
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.teal.withOpacity(0.1)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: Offset(0, 2))
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20),
                                      SizedBox(height: 8),
                                      Expanded(
                                        child: Text(
                                          data['title'] ?? 'Note',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        "Saved",
                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  "Your Subjects",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: (semester == 'S1' || semester == 'S2')
                      ? FirebaseFirestore.instance
                            .collection('notes')
                            .where('semester', isEqualTo: semester)
                            .snapshots()
                      : FirebaseFirestore.instance
                            .collection('notes')
                            .where('branch', isEqualTo: branch)
                            .where('semester', isEqualTo: semester)
                            .snapshots(),
                  builder: (context, noteSnapshot) {
                    if (noteSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var validDocs = noteSnapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data.containsKey('subject');
                    }).toList();

                    var subjects = validDocs
                        .map((doc) => doc['subject'] as String)
                        .toSet()
                        .toList();

                    if (subjects.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "No subjects found for $semester $branch yet.\n\n(Admin must add notes with the correct branch/sem labels)",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent.withOpacity(
                                0.2,
                              ),
                              child: const Icon(Icons.book, color: Colors.teal),
                            ),
                            title: Text(
                              subjects[index],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: const Text("View all modules"),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ModuleListScreen(
                                    branch: branch,
                                    semester: semester,
                                    subject: subjects[index],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StudentUploadScreen()),
          );
        },
        icon: const Icon(Icons.upload_file),
        label: const Text("Upload Note"),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildToolCard(
      BuildContext context, String label, IconData icon, Color color, VoidCallback onTap,
      {bool isPremiumOnly = false, bool isSubscribed = false}) {
    bool isLocked = isPremiumOnly && !isSubscribed;
    
    return GestureDetector(
      onTap: () {
        if (isLocked) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SubscriptionScreen()),
          );
        } else {
          onTap();
        }
      },
      child: Container(
        width: 80,
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            )
          ],
          border: Border.all(color: color.withOpacity(0.05)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: isLocked ? 0.4 : 1.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 22),
                  SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color is MaterialColor ? color.shade700 : color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isLocked)
              const Positioned(
                top: 5,
                right: 5,
                child: Icon(Icons.lock, size: 16, color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }
}
