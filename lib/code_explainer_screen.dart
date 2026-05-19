import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_config.dart';

class CodeExplainerScreen extends StatefulWidget {
  @override
  _CodeExplainerScreenState createState() => _CodeExplainerScreenState();
}

class _CodeExplainerScreenState extends State<CodeExplainerScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String _explanation = '';
  String _errorMessage = '';

  Future<void> _explainCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please paste some code to explain.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _explanation = '';
    });

    // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    try {
      // Update with your actual server URL if deployed
      final uri = Uri.parse(ApiConfig.explainCode);
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'userId': FirebaseAuth.instance.currentUser?.uid,
        }),
      ).timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _explanation = data['explanation'] ?? 'No explanation generated.';
        });
      } else {
        setState(() {
          _errorMessage = 'Server Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Explanation failed: $e\nEnsure the backend is running.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CSE Code Explainer 💻'),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Code Input Area
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _codeController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Paste your C++, Python, Java, etc. code here...',
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _explainCode,
                    icon: _isLoading 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(Icons.psychology),
                    label: Text(_isLoading ? 'Analyzing...' : 'Explain Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ],
              ),
            ),
            
            // Explanation Area
            Expanded(
              child: _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(_errorMessage, style: TextStyle(color: Colors.red[700]), textAlign: TextAlign.center),
                    )
                  )
                : _explanation.isEmpty
                  ? Center(
                      child: Text(
                        "Paste a code snippet and tap 'Explain Code'.", 
                        style: TextStyle(color: Colors.grey[500], fontSize: 16)
                      )
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                        ),
                        child: MarkdownBody(
                          data: _explanation,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(fontSize: 15, height: 1.6),
                            codeblockDecoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
