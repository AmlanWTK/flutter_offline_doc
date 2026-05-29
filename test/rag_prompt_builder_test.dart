import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/chunk.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/rag_prompt_builder.dart';

void main() {
  test('buildContextBlock formats excerpts', () {
    final chunks = [
      Chunk(id: '1', documentId: 'd', text: 'First part.', index: 0),
      Chunk(id: '2', documentId: 'd', text: 'Second part.', index: 1),
    ];

    final block = RagPromptBuilder.buildContextBlock(chunks);

    expect(block, contains('Excerpt 1'));
    expect(block, contains('First part.'));
    expect(block, contains('Excerpt 2'));
  });

  test('buildUserMessage includes query and context', () {
    final message = RagPromptBuilder.buildUserMessage(
      'When is payment due?',
      [
        Chunk(
          id: '1',
          documentId: 'd',
          text: 'Payment within thirty days.',
          index: 0,
        ),
      ],
    );

    expect(message, contains('When is payment due?'));
    expect(message.toLowerCase(), contains('payment'));
  });
}
