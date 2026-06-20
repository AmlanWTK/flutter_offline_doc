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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'referenceChunkIds': referenceChunkIds,
    };
  }

  factory Message.fromMap(Map<dynamic, dynamic> map) {
    return Message(
      id: map['id'] as String,
      documentId: map['documentId'] as String,
      content: map['content'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      referenceChunkIds: (map['referenceChunkIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
