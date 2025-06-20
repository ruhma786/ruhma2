import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'task.dart';

// Function to export tasks to PDF
Future<void> exportTasksToPDF(BuildContext context, List<Task> tasks) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Tasks List', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            for (var task in tasks)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Title: ${task.title}'),
                  pw.Text('Description: ${task.description}'),
                  pw.Text('Due Date: ${task.dueDate}'),
                  pw.Text('Repeat: ${task.isRepeated ? "Yes" : "No"}'),
                  pw.Text('Completed: ${task.isCompleted ? "Yes" : "No"}'),
                  pw.SizedBox(height: 10),
                ],
              ),
          ],
        );
      },
    ),
  );

  // This will create the PDF and show it
  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());

  // Show confirmation to the user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Tasks exported to PDF')),
  );
}
