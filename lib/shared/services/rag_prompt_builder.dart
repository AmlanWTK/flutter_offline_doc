import 'package:flutter_offline_ai_doc_chat/shared/models/chunk.dart';

/// Builds RAG prompts shared by local and cloud answer backends.
class RagPromptBuilder {
  static const String systemInstruction = '''
You answer questions about a user document using ONLY the excerpts provided below.
If the excerpts do not contain enough information, say you cannot find it in the document.
Do not invent facts. Be concise and cite ideas from the excerpts when possible.
''';

  static String buildContextBlock(List<Chunk> chunks) {
    if (chunks.isEmpty) {
      return '(No matching excerpts were found in the document.)';
    }

    final buffer = StringBuffer();
    for (var i = 0; i < chunks.length; i++) {
      buffer.writeln('--- Excerpt ${i + 1} ---');
      buffer.writeln(chunks[i].text.trim());
      if (i < chunks.length - 1) buffer.writeln();
    }
    return buffer.toString().trim();
  }

  static String buildUserMessage(String query, List<Chunk> chunks) {
    return '''
Document excerpts:
${buildContextBlock(chunks)}

Question: $query
''';
  }
}
