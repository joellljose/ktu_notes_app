import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class NoteDetailScreen extends StatelessWidget {
  final String title;
  final String pdfUrl;
  final String summary;

  NoteDetailScreen({required this.title, required this.pdfUrl, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          // PDF Viewer
          Expanded(
            flex: 3,
            child: SfPdfViewer.network(pdfUrl),
          ),
          // AI Summary Section
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AI-Generated Summary", 
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Divider(),
                    Text(summary, style: TextStyle(fontSize: 16, height: 1.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}