import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class NoteDetailScreen extends StatelessWidget {
  final String title;
  final String pdfUrl;
  final String summary;

  NoteDetailScreen({
    required this.title,
    required this.pdfUrl,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // 1. PDF Viewer Section (Top half)
          Expanded(
            flex: 3,
            child: SfPdfViewer.network(pdfUrl),
          ),

          // 2. AI Summary Section (Bottom half)
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text("AI Quick Summary", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        summary,
                        style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
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