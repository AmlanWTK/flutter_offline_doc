import 'package:flutter_offline_ai_doc_chat/shared/models/chunk.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document.dart';
import 'package:uuid/uuid.dart';

abstract class RetrievalService {
  List<Chunk> chunkDocument(Document doc, {int chunkSize = 500});
  List<Chunk> searchRelevantChunks(String query, List<Chunk> chunks, {int topK = 3});
  Future<String> generateAnswer(String query, List<Chunk> relevantChunks);
}

class RetrievalServiceImpl implements RetrievalService {
  @override
  List<Chunk> chunkDocument(Document doc, {int chunkSize = 500}) {
    if (doc.extractedText.isEmpty) return [];

    final text = doc.extractedText;
    final List<Chunk> chunks = [];
    final uuid = const Uuid();

    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      chunks.add(Chunk(
        id: uuid.v4(),
        documentId: doc.id,
        text: text.substring(i, end),
        index: chunks.length,
      ));
    }

    return chunks;
  }

  @override
  List<Chunk> searchRelevantChunks(String query, List<Chunk> chunks, {int topK = 3}) {
    final splitRegex = RegExp(r'[\s\p{P}]+', unicode: true);
    final queryWords = query.toLowerCase().split(splitRegex).where((w) => w.isNotEmpty).toSet();
    if (queryWords.isEmpty) return [];

    final Map<Chunk, int> scores = {};

    for (final chunk in chunks) {
      final chunkWords = chunk.text.toLowerCase().split(splitRegex);
      int score = 0;
      for (final word in queryWords) {
        if (chunkWords.contains(word)) {
          score++;
        }
      }
      scores[chunk] = score;
    }

    final sortedChunks = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    return sortedChunks.take(topK).where((c) => scores[c]! > 0).toList();
  }

  @override
  Future<String> generateAnswer(String query, List<Chunk> relevantChunks) async {
    // For MVP offline, we just return an extractive answer by concatenating the chunks.
    // In a real implementation with local LLM, we would pass these chunks as context to the model.
    if (relevantChunks.isEmpty) {
      return "I couldn't find any information related to your question in this document.";
    }

    final buffer = StringBuffer();
    buffer.writeln("Based on the document, here are the most relevant excerpts:");
    buffer.writeln();
    for (int i = 0; i < relevantChunks.length; i++) {
      buffer.writeln("--- Excerpt ${i + 1} ---");
      buffer.writeln(relevantChunks[i].text.trim());
      buffer.writeln();
    }

    return buffer.toString();
  }
}
