import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDetailScreen extends StatelessWidget {
  final String title;
  final String pdfUrl;
  final String summary;

  NoteDetailScreen({
    required this.title,
    required this.pdfUrl,
    required this.summary,
  });

  // Function to open the link in a browser for downloading
  Future<void> _downloadFile() async {
    final Uri url = Uri.parse(pdfUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $pdfUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            tooltip: "Download PDF",
            onPressed: _downloadFile,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. PDF Viewer Section (Top half)
          Expanded(
            flex: 3,
            child: SfPdfViewer.network(
              pdfUrl,
              // Handles loading errors if the Drive link is private
              onDocumentLoadFailed: (details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Ensure Google Drive file is set to 'Anyone with link'")),
                );
              },
            ),
          ),

          // 2. AI Summary Section (Bottom half)
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Text(
                        "AI Summary",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Divider(height: 25),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Text(
                        summary,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}