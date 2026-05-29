import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_offline_ai_doc_chat/app/di/service_locator.dart';
import 'package:flutter_offline_ai_doc_chat/core/database/local_database.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document_category.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _db = sl<LocalDatabase>();
  final _searchController = TextEditingController();

  List<Document> _documents = [];
  String _query = '';
  DocumentCategory _selectedCategory = DocumentCategory.all;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDocuments() {
    setState(() {
      _documents = _query.isEmpty
          ? _db.getDocumentsByCategory(_selectedCategory)
          : _db.searchDocuments(_query, category: _selectedCategory);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'My Documents',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search documents...',
                  leading: Icon(Icons.search, color: cs.onSurfaceVariant),
                  onChanged: (v) {
                    _query = v;
                    _loadDocuments();
                  },
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    cs.surfaceContainerHighest.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),

          // ── Category Chips ──
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: DocumentCategory.values
                    .where((c) => c != DocumentCategory.all)
                    .length + 1,
                itemBuilder: (context, index) {
                  final cats = [
                    DocumentCategory.all,
                    ...DocumentCategory.values.where((c) => c != DocumentCategory.all),
                  ];
                  final cat = cats[index];
                  final isSelected = _selectedCategory == cat;
                  return _CategoryChip(
                    category: cat,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _loadDocuments();
                    },
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Doc count ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_documents.length} document${_documents.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // ── Document List ──
          _documents.isEmpty
              ? SliverFillRemaining(child: _buildEmpty())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      return _DocumentCard(
                        doc: doc,
                        onTap: () async {
                          await context.push('/document/${doc.id}');
                          _loadDocuments();
                        },
                        onDelete: () => _deleteDocument(doc),
                        onChat: () => context.push('/chat/${doc.id}'),
                      );
                    },
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/capture');
          _loadDocuments();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Document'),
        elevation: 2,
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined,
              size: 80, color: Colors.grey.withOpacity(0.35)),
          const SizedBox(height: 16),
          Text(
            _query.isEmpty
                ? 'No documents here yet.\nTap + to add your first one!'
                : 'No results for "$_query".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], height: 1.7, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDocument(Document doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteDocument(doc.id);
      _loadDocuments();
    }
  }
}

// ─── Category chip ───────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final DocumentCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = category == DocumentCategory.all
        ? Theme.of(context).colorScheme.primary
        : category.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 15,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Document card ────────────────────────────────────────────────────────────
class _DocumentCard extends StatelessWidget {
  final Document doc;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onChat;

  const _DocumentCard({
    required this.doc,
    required this.onTap,
    required this.onDelete,
    required this.onChat,
  });

  IconData get _sourceIcon {
    switch (doc.sourceType) {
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'camera': return Icons.camera_alt_outlined;
      default: return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = doc.category == DocumentCategory.all
        ? cs.primary
        : doc.category.color;

    final preview = doc.extractedText.length > 100
        ? '${doc.extractedText.substring(0, 100)}...'
        : doc.extractedText;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ──
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: doc.imagePath != null && File(doc.imagePath!).existsSync()
                      ? Image.file(File(doc.imagePath!), fit: BoxFit.cover)
                      : Container(
                          color: catColor.withOpacity(0.12),
                          child: Icon(_sourceIcon, color: catColor, size: 26),
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // ── Content ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doc.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            doc.category.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: catColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.isEmpty ? 'No extracted text' : preview,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: cs.outline),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(doc.createdAt),
                          style: TextStyle(fontSize: 11, color: cs.outline),
                        ),
                        const Spacer(),
                        // Quick chat button
                        GestureDetector(
                          onTap: onChat,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 13, color: cs.onPrimaryContainer),
                                const SizedBox(width: 4),
                                Text('Chat',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onPrimaryContainer)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon:
                              Icon(Icons.more_vert, color: cs.outline, size: 20),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                          onSelected: (v) {
                            if (v == 'delete') onDelete();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
