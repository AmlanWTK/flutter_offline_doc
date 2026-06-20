import 'dart:io';

import 'package:flutter_offline_ai_doc_chat/shared/models/message.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document_category.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/storage_stats.dart';

class LocalDatabase {
  static const String _documentsBoxName = 'documents';
  static const String _chatBoxName = 'chat_messages';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_documentsBoxName);
    await Hive.openBox<Map>(_chatBoxName);
  }

  static Box<Map> get _box => Hive.box<Map>(_documentsBoxName);

  // ─── Save ───────────────────────────────────────────────
  Future<void> saveDocument(Document doc) async {
    await _box.put(doc.id, _toMap(doc));
  }

  // ─── Get all ────────────────────────────────────────────
  List<Document> getAllDocuments() {
    return _box.values
        .map((m) => _fromMap(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ─── Get by category ─────────────────────────────────────
  List<Document> getDocumentsByCategory(DocumentCategory category) {
    if (category == DocumentCategory.all) return getAllDocuments();
    return getAllDocuments().where((d) => d.category == category).toList();
  }

  // ─── Get single ─────────────────────────────────────────
  Document? getDocument(String id) {
    final m = _box.get(id);
    if (m == null) return null;
    return _fromMap(Map<String, dynamic>.from(m));
  }

  // ─── Delete ─────────────────────────────────────────────
  Future<void> deleteDocument(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAllDocuments() async {
    await _box.clear();
  }

  Future<StorageStats> getStorageStats() async {
    final docs = getAllDocuments();
    var imageBytes = 0;
    var textBytes = 0;

    for (final doc in docs) {
      textBytes += doc.extractedText.length + doc.title.length;
      final path = doc.imagePath;
      if (path == null) continue;
      final file = File(path);
      if (await file.exists()) {
        imageBytes += await file.length();
      }
    }

    return StorageStats(
      documentCount: docs.length,
      imageBytes: imageBytes,
      textBytes: textBytes,
    );
  }

  // ─── Search ─────────────────────────────────────────────
  List<Document> searchDocuments(String query, {DocumentCategory? category}) {
    final q = query.toLowerCase();
    var docs = category == null || category == DocumentCategory.all
        ? getAllDocuments()
        : getDocumentsByCategory(category);
    return docs.where((doc) {
      return doc.title.toLowerCase().contains(q) ||
          doc.extractedText.toLowerCase().contains(q) ||
          doc.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  // ─── Serialisation ──────────────────────────────────────
  Map<String, dynamic> _toMap(Document doc) => {
        'id': doc.id,
        'title': doc.title,
        'extractedText': doc.extractedText,
        'createdAt': doc.createdAt.toIso8601String(),
        'tags': doc.tags,
        'sourceType': doc.sourceType,
        'imagePath': doc.imagePath,
        'category': doc.category.name,
      };

  Document _fromMap(Map<String, dynamic> m) {
    final categoryName = m['category'] as String? ?? 'personal';
    final category = DocumentCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => DocumentCategory.personal,
    );
    return Document(
      id: m['id'] as String,
      title: m['title'] as String,
      extractedText: m['extractedText'] as String,
      createdAt: DateTime.parse(m['createdAt'] as String),
      tags: List<String>.from(m['tags'] as List),
      sourceType: m['sourceType'] as String,
      imagePath: m['imagePath'] as String?,
      category: category,
    );
  }

  // ─── Chat Messages ──────────────────────────────────────
  static Box<Map> get _chatBox => Hive.box<Map>(_chatBoxName);

  Future<void> saveMessages(String documentId, List<Message> messages) async {
    final serialized = messages.map((m) => m.toMap()).toList();
    await _chatBox.put(documentId, {'messages': serialized});
  }

  List<Message> getChatHistory(String documentId) {
    final data = _chatBox.get(documentId);
    if (data == null || data['messages'] == null) return [];
    final list = data['messages'] as List<dynamic>;
    return list.map((m) => Message.fromMap(Map<String, dynamic>.from(m as Map))).toList();
  }

  Future<void> deleteChatHistory(String documentId) async {
    await _chatBox.delete(documentId);
  }
}
