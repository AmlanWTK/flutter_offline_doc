import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/retrieval_service.dart';

void main() {
  late RetrievalService service;

  setUp(() {
    service = RetrievalServiceImpl();
  });

  group('RetrievalServiceImpl', () {
    test('chunkDocument splits text into fixed-size chunks', () {
      final doc = Document(
        id: 'doc-1',
        title: 'Test',
        extractedText: 'a' * 1200,
        createdAt: DateTime(2026, 1, 1),
        sourceType: 'image',
      );

      final chunks = service.chunkDocument(doc, chunkSize: 500);

      expect(chunks.length, 3);
      expect(chunks.first.index, 0);
      expect(chunks.last.text.length, 200);
    });

    test('chunkDocument returns empty list for blank text', () {
      final doc = Document(
        id: 'doc-1',
        title: 'Empty',
        extractedText: '',
        createdAt: DateTime(2026, 1, 1),
        sourceType: 'image',
      );

      expect(service.chunkDocument(doc), isEmpty);
    });

    test('searchRelevantChunks ranks chunks by keyword overlap', () {
      final chunks = service.chunkDocument(
        Document(
          id: 'doc-1',
          title: 'Notes',
          extractedText:
              'Photosynthesis converts light into energy. '
              'Plants use chlorophyll in leaves. '
              'The mitochondria produce ATP in cells.',
          createdAt: DateTime(2026, 1, 1),
          sourceType: 'image',
        ),
        chunkSize: 80,
      );

      final results = service.searchRelevantChunks(
        'How do plants make energy?',
        chunks,
        topK: 2,
      );

      expect(results, isNotEmpty);
      expect(
        results.first.text.toLowerCase(),
        contains('photosynthesis'),
      );
    });

    test('searchRelevantChunks returns empty for unrelated query', () {
      final chunks = service.chunkDocument(
        Document(
          id: 'doc-1',
          title: 'Receipt',
          extractedText: 'Coffee shop receipt total five dollars',
          createdAt: DateTime(2026, 1, 1),
          sourceType: 'image',
        ),
      );

      final results = service.searchRelevantChunks('quantum physics', chunks);

      expect(results, isEmpty);
    });

    test('generateAnswer returns helpful message when no chunks match', () async {
      final answer = await service.generateAnswer('missing topic', []);

      expect(answer, contains("couldn't find"));
    });

    test('generateAnswer returns excerpts from relevant chunks', () async {
      final chunks = service.chunkDocument(
        Document(
          id: 'doc-1',
          title: 'Contract',
          extractedText: 'Payment is due within thirty days of invoice date.',
          createdAt: DateTime(2026, 1, 1),
          sourceType: 'pdf',
        ),
      );

      final answer = await service.generateAnswer('When is payment due?', chunks);

      expect(answer, contains('Excerpt'));
      expect(answer.toLowerCase(), contains('payment'));
    });
  });
}
