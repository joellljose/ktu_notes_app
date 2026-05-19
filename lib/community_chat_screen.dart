import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/api_config.dart';

class CommunityChatScreen extends StatefulWidget {
  final String branch;
  final String semester;

  const CommunityChatScreen({
    Key? key,
    required this.branch,
    required this.semester,
  }) : super(key: key);

  @override
  _CommunityChatScreenState createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isSending = false;

  void _sendMessage() async {
    final rawText = _messageController.text.trim();
    if (rawText.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    // AI Moderation Step
    try {
      // Fetch recent history for context
      String chatId = "${widget.branch}_${widget.semester}";
      final historySnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      final history = historySnapshot.docs
          .map((doc) => doc['text'] as String)
          .toList()
          .reversed
          .toList();

      final modResponse = await http.post(
        Uri.parse(ApiConfig.moderateMessage),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': rawText,
          'history': history,
        }),
      ).timeout(const Duration(seconds: 10));

      if (modResponse.statusCode == 200) {
        final modData = jsonDecode(modResponse.body);
        if (modData['is_academic'] == false) {
          setState(() => _isSending = false);
          _showModerationWarning(modData['warning_reason'] ?? "Please keep discussions academic.");
          return;
        }
      }
    } catch (e) {
      print("Moderation service unavailable: $e. Proceeding...");
    }

    String message = rawText;
    _messageController.clear();

    // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    
    
    String chatId = "${widget.branch}_${widget.semester}";

    try {
      await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(chatId)
          .collection('messages')
          .add({
            'text': message,
            'senderId': currentUser?.uid,
            'senderEmail': currentUser?.email,
            'timestamp': FieldValue.serverTimestamp(),
          });

      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, 
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      print("Error sending message: $e");
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showModerationWarning(String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text("Class Chat Rule"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This chat is strictly for academic purposes and study-related doubts.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Text(
                reason,
                style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("I Understand", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String chatId = "${widget.branch}_${widget.semester}";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Class Chat"),
            Text(
              "${widget.semester} | ${widget.branch}",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classrooms')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text("No messages yet. Say Hi!"));
                }

                return ListView.builder(
                  reverse: true, 
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUser?.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: isMe
                                ? Radius.circular(12)
                                : Radius.zero,
                            bottomRight: isMe
                                ? Radius.zero
                                : Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                (data['senderEmail'] as String).split(
                                  '@',
                                )[0], 
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            Text(
                              data['text'],
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Ask a doubt...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: _isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
