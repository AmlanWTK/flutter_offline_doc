import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_offline_ai_doc_chat/shared/models/document.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document_category.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/message.dart';

class ExportService {
  Future<bool> exportAsMarkdown(Document doc) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('# ${doc.title}');
      buffer.writeln();
      buffer.writeln('**Date:** ${_formatDate(doc.createdAt)}  ');
      buffer.writeln('**Category:** ${doc.category.label}  ');
      buffer.writeln('**Source:** ${doc.sourceType}  ');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## Extracted Text');
      buffer.writeln();
      buffer.writeln(doc.extractedText);

      await _shareTextFile(
        content: buffer.toString(),
        filename: '${_sanitize(doc.title)}.md',
        mimeType: 'text/markdown',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> exportChatAsMarkdown(Document doc, List<Message> messages) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('# Chat: ${doc.title}');
      buffer.writeln();
      buffer.writeln('**Exported on:** ${_formatDate(DateTime.now())}');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();

      for (final msg in messages) {
        final role = msg.role == MessageRole.user ? '**You**' : '**AI**';
        buffer.writeln('$role  ');
        buffer.writeln(msg.content);
        buffer.writeln();
      }

      await _shareTextFile(
        content: buffer.toString(),
        filename: 'chat_${_sanitize(doc.title)}.md',
        mimeType: 'text/markdown',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> exportAsPdf(Document doc) async {
    try {
      final pdfDoc = pw.Document();

      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            pw.Text(
              doc.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Date: ${_formatDate(doc.createdAt)} | Category: ${doc.category.label}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
            pw.Divider(height: 24),
            pw.Header(level: 1, text: 'Extracted Text'),
            pw.SizedBox(height: 8),
            pw.Text(
              doc.extractedText,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
            ),
          ],
        ),
      );

      await _sharePdfFile(pdfDoc, '${_sanitize(doc.title)}.pdf');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _shareTextFile({
    required String content,
    required String filename,
    required String mimeType,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
      ),
    );
  }

  Future<void> _sharePdfFile(pw.Document pdfDoc, String filename) async {
    final bytes = await pdfDoc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
      ),
    );
  }

  String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
