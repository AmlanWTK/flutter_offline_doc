import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_offline_ai_doc_chat/app/di/service_locator.dart';
import 'package:flutter_offline_ai_doc_chat/core/database/local_database.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document_category.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/export_service.dart';

class DocumentDetailScreen extends StatelessWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    final db = sl<LocalDatabase>();
    final doc = db.getDocument(documentId);

    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document')),
        body: const Center(child: Text('Document not found.')),
      );
    }
    return _DocumentDetailView(doc: doc);
  }
}

class _DocumentDetailView extends StatelessWidget {
  final Document doc;
  const _DocumentDetailView({required this.doc});

  Future<void> _exportDocument(
    BuildContext context,
    Future<bool> Function() export,
    String successMessage,
  ) async {
    final ok = await export();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? successMessage : 'Export failed.')),
    );
  }

  void _showExportSheet(BuildContext context) {
    final exportService = sl<ExportService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Export Document',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Choose a format to share or save.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
            const SizedBox(height: 20),
            _ExportTile(
              icon: Icons.description_outlined,
              color: const Color(0xFF0077B6),
              title: 'Export as Markdown',
              subtitle: 'Plain text with formatting (.md)',
              onTap: () {
                Navigator.pop(ctx);
                _exportDocument(
                  context,
                  () => exportService.exportAsMarkdown(doc),
                  'Markdown exported.',
                );
              },
            ),
            const SizedBox(height: 10),
            _ExportTile(
              icon: Icons.picture_as_pdf_outlined,
              color: const Color(0xFFD62839),
              title: 'Export as PDF',
              subtitle: 'Formatted document (.pdf)',
              onTap: () {
                Navigator.pop(ctx);
                _exportDocument(
                  context,
                  () => exportService.exportAsPdf(doc),
                  'PDF exported.',
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = doc.category.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Export',
            onPressed: () => _showExportSheet(context),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: () => context.push('/chat/${doc.id}'),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Chat'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            if (doc.imagePath != null && File(doc.imagePath!).existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(doc.imagePath!),
                    width: double.infinity, height: 220, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],

            // Metadata row
            Row(
              children: [
                _MetaChip(icon: _sourceIcon(doc.sourceType),
                    label: doc.sourceType.toUpperCase()),
                const SizedBox(width: 8),
                _MetaChip(icon: Icons.calendar_today_outlined,
                    label: _formatDate(doc.createdAt)),
                const SizedBox(width: 8),
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(doc.category.icon, size: 13, color: catColor),
                      const SizedBox(width: 5),
                      Text(doc.category.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: catColor)),
                    ],
                  ),
                ),
              ],
            ),

            // Tags
            if (doc.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: doc.tags
                    .map((t) => Chip(
                          label: Text(t),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: cs.secondaryContainer,
                          labelStyle: TextStyle(
                              color: cs.onSecondaryContainer, fontSize: 12),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Extracted text
            Row(
              children: [
                Icon(Icons.text_snippet_outlined, color: cs.primary, size: 16),
                const SizedBox(width: 6),
                Text('Extracted Text',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: cs.primary)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
              ),
              child: SelectableText(
                doc.extractedText.isEmpty
                    ? 'No text was extracted from this document.'
                    : doc.extractedText,
                style: const TextStyle(height: 1.6, fontSize: 14),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/chat/${doc.id}'),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Ask a Question'),
        elevation: 2,
      ),
    );
  }

  IconData _sourceIcon(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'camera': return Icons.camera_alt_outlined;
      default: return Icons.image_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSecondaryContainer)),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
