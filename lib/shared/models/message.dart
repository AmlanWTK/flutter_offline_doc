import 'package:equatable/equatable.dart';

enum MessageRole { user, system, ai }

class Message extends Equatable {
  final String id;
  final String documentId;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final List<String> referenceChunkIds;

  const Message({
    required this.id,
    required this.documentId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.referenceChunkIds = const [],
  });

  @override
  List<Object?> get props => [id, documentId, content, role, timestamp, referenceChunkIds];
}
