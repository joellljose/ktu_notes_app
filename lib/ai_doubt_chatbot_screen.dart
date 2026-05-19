import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_config.dart';

class AiDoubtChatbotScreen extends StatefulWidget {
  final String branch;
  final String semester;

  const AiDoubtChatbotScreen({
    Key? key,
    required this.branch,
    required this.semester,
  }) : super(key: key);

  @override
  State<AiDoubtChatbotScreen> createState() => _AiDoubtChatbotScreenState();
}

class _AiDoubtChatbotScreenState extends State<AiDoubtChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // Note: Adjust the backend URL based on your environment.

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add({
      'role': 'ai',
      'text': 'Hello! I am your KTU Doubt Assistant. Ask me anything based on your course notes!',
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _isLoading = true;
    });
    
    // Dismiss the keyboard
    FocusScope.of(context).unfocus();
    
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.askDoubt),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': text,
          'history': _messages.sublist(0, _messages.length - 1), // Send history except the current query
          'branch': widget.branch,
          'semester': widget.semester,
          'userId': FirebaseAuth.instance.currentUser?.uid,
        }),
      ).timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages.add({'role': 'ai', 'text': data['answer']});
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'ai',
            'text': 'Sorry, I encountered an error. Please try again later.',
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'text': 'Network error. Please check your connection.',
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Doubt Resolver'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return _ChatBubble(
                  text: message['text']!,
                  isUser: isUser,
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask a doubt...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey.withOpacity(0.1),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.teal,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.teal : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: isUser
            ? Text(
                text,
                style: const TextStyle(color: Colors.white),
              )
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                ),
              ),
      ),
    );
  }
}
