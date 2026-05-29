import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_offline_ai_doc_chat/app/di/service_locator.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/document_capture_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/ocr_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/pdf_extraction_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document_category.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/ocr_language.dart';
import 'package:flutter_offline_ai_doc_chat/core/database/local_database.dart';
import 'package:flutter_offline_ai_doc_chat/core/utils/platform_utils.dart';

class DocumentCaptureScreen extends StatefulWidget {
  const DocumentCaptureScreen({super.key});

  @override
  State<DocumentCaptureScreen> createState() => _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends State<DocumentCaptureScreen> {
  final _captureService = sl<DocumentCaptureService>();
  final _ocrService = sl<OcrService>();
  final _pdfService = sl<PdfExtractionService>();
  final _db = sl<LocalDatabase>();

  bool _isProcessing = false;
  String _extractedText = '';
  File? _imageFile;
  String _statusMessage = '';
  OcrLanguage _ocrLanguage = OcrLanguage.englishAndBangla;

  Future<void> _processImage(File file) async {
    setState(() {
      _isProcessing = true;
      _extractedText = '';
      _statusMessage = 'Cropping image...';
    });

    try {
      if (!supportsOcrCapture) {
        setState(() {
          _extractedText =
              'OCR is available on Android and iOS. Use a mobile device to scan documents, '
              'or paste text manually in a future update.';
          _statusMessage = '';
        });
        return;
      }

      final cropped = await _captureService.cropImage(file, context);
      final finalFile = cropped ?? file;
      setState(() {
        _imageFile = finalFile;
        _statusMessage = 'Extracting text via OCR...';
      });
      final text = await _ocrService.extractTextFromImage(
        finalFile,
        language: _ocrLanguage,
      );
      setState(() {
        _extractedText = text.isEmpty ? 'No text detected in image.' : text;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _extractedText = 'Error extracting text: $e';
        _statusMessage = '';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveDocument() async {
    if (_extractedText.isEmpty || _extractedText.startsWith('Error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid text to save.')),
      );
      return;
    }

    final titleController = TextEditingController(
      text: 'Document ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );
    DocumentCategory pickedCategory = DocumentCategory.personal;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text('Save Document',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                // Title
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Document title',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.drive_file_rename_outline_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),

                // Category
                Text('Category',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DocumentCategory.values
                      .where((c) => c != DocumentCategory.all)
                      .map((cat) {
                    final isSelected = pickedCategory == cat;
                    return GestureDetector(
                      onTap: () => setModalState(() => pickedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color
                              : cat.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon,
                                size: 14,
                                color: isSelected ? Colors.white : cat.color),
                            const SizedBox(width: 6),
                            Text(cat.label,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : cat.color)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Save to Library'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );

    if (confirmed == true && mounted) {
      final doc = Document(
        id: const Uuid().v4(),
        title: titleController.text.trim().isEmpty
            ? 'Untitled Document'
            : titleController.text.trim(),
        extractedText: _extractedText,
        createdAt: DateTime.now(),
        sourceType: _imageFile != null ? 'image' : 'pdf',
        imagePath: _imageFile?.path,
        category: pickedCategory,
      );

      await _db.saveDocument(doc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Document saved!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go('/');
      }
    }
  }

  void _onCamera() async {
    final file = await _captureService.captureFromCamera();
    if (file != null) await _processImage(file);
  }

  void _onGallery() async {
    final file = supportsOcrCapture
        ? await _captureService.pickFromGallery()
        : await _captureService.pickImageFile();
    if (file != null) await _processImage(file);
  }

  Future<void> _onPdf() async {
    final file = await _captureService.pickPdf();
    if (file == null) return;

    setState(() {
      _isProcessing = true;
      _extractedText = '';
      _statusMessage = 'Opening PDF...';
    });

    try {
      final text = await _pdfService.extractTextFromPdf(
        file,
        language: _ocrLanguage,
        onProgress: (current, total) {
          if (!mounted) return;
          setState(() {
            _statusMessage = 'Processing page $current of $total...';
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _extractedText = text.isEmpty ? 'No text detected in PDF.' : text;
        _isProcessing = false;
        _statusMessage = '';
        _imageFile = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _extractedText = 'Error processing PDF: $e';
        _isProcessing = false;
        _statusMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Document'),
        actions: [
          if (_extractedText.isNotEmpty && !_extractedText.startsWith('Error'))
            TextButton.icon(
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save'),
              onPressed: _saveDocument,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Source buttons ──
                  Row(
                    children: [
                      if (supportsCameraCapture) ...[
                        Expanded(
                          child: _SourceButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            onTap: _onCamera,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: _SourceButton(
                          icon: Icons.photo_library_outlined,
                          label: supportsOcrCapture ? 'Gallery' : 'Image',
                          onTap: _onGallery,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SourceButton(
                          icon: Icons.picture_as_pdf_outlined,
                          label: 'PDF',
                          onTap: () => _onPdf(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── OCR language ──
                  if (supportsOcrCapture) ...[
                    Row(
                      children: [
                        Icon(Icons.translate_outlined,
                            size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text('OCR Language',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: OcrLanguage.values.map((lang) {
                        final selected = _ocrLanguage == lang;
                        return ChoiceChip(
                          label: Text(lang.label),
                          selected: selected,
                          onSelected: _isProcessing
                              ? null
                              : (_) => setState(() => _ocrLanguage = lang),
                        );
                      }).toList(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _ocrLanguage.subtitle,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Image preview ──
                  if (_imageFile != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _imageFile!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Extracted text ──
                  if (_extractedText.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.text_snippet_outlined,
                            size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text('Extracted Text',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: cs.outlineVariant.withOpacity(0.3)),
                      ),
                      child: Text(
                        _extractedText,
                        style: const TextStyle(height: 1.5, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saveDocument,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save to Library'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],

                  // ── Empty state ──
                  if (_extractedText.isEmpty && _imageFile == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.document_scanner_outlined,
                                size: 48, color: cs.primary),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Choose a source above\nto scan or import a document',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: cs.onSurfaceVariant,
                                height: 1.6,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: cs.onPrimaryContainer),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
