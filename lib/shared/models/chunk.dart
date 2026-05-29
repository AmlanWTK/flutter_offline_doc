import 'package:equatable/equatable.dart';

class Chunk extends Equatable {
  final String id;
  final String documentId;
  final String text;
  final int index;

  const Chunk({
    required this.id,
    required this.documentId,
    required this.text,
    required this.index,
  });

  @override
  List<Object?> get props => [id, documentId, text, index];
}
