import 'package:equatable/equatable.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document_category.dart';

class Document extends Equatable {
  final String id;
  final String title;
  final String extractedText;
  final DateTime createdAt;
  final List<String> tags;
  final String sourceType; // 'pdf', 'camera', 'gallery'
  final String? imagePath;
  final DocumentCategory category;

  const Document({
    required this.id,
    required this.title,
    required this.extractedText,
    required this.createdAt,
    this.tags = const [],
    required this.sourceType,
    this.imagePath,
    this.category = DocumentCategory.personal,
  });

  Document copyWith({
    String? title,
    String? extractedText,
    List<String>? tags,
    String? imagePath,
    DocumentCategory? category,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt,
      tags: tags ?? this.tags,
      sourceType: sourceType,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, extractedText, createdAt, tags, sourceType, imagePath, category];
}
