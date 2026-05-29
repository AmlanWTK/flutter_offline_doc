import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_offline_ai_doc_chat/core/storage/app_preferences.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/answer_mode.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/chunk.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/answer_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/cloud_llm_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/local_llm_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/retrieval_service.dart';
import 'package:hive/hive.dart';

class _FakeCloud implements CloudLlmService {
  @override
  Future<String> generateAnswer(String query, List<Chunk> relevantChunks) async {
    return 'Cloud answer for: $query (${relevantChunks.length} chunks)';
  }
}

class _FakeLocal implements LocalLlmService {
  @override
  bool get isModelLoaded => false;

  @override
  String? get loadedModelPath => null;

  @override
  Future<String> generateAnswer(String query, List<Chunk> relevantChunks) async {
    return 'Local answer';
  }

  @override
  Future<String?> loadModelFromPreferences() async => null;

  @override
  void dispose() {}
}

void main() {
  late RetrievalService retrieval;
  late AppPreferences prefs;

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('hive_answer_test');
    Hive.init(dir.path);
    await AppPreferences.initialize();
  });

  setUp(() {
    retrieval = RetrievalServiceImpl();
    prefs = AppPreferences();
  });

  test('answerQuestion uses excerpt mode by default', () async {
    await prefs.setAnswerMode(AnswerMode.excerpts);

    final answerService = AnswerServiceImpl(
      retrieval,
      _FakeLocal(),
      _FakeCloud(),
      prefs,
    );

    final result = await answerService.answerQuestion(
      document: Document(
        id: 'doc-1',
        title: 'Notes',
        extractedText: 'Photosynthesis uses light energy in plants.',
        createdAt: DateTime(2026, 1, 1),
        sourceType: 'image',
      ),
      query: 'How do plants use light?',
    );

    expect(result.mode, AnswerMode.excerpts);
    expect(result.content.toLowerCase(), contains('excerpt'));
  });

  test('answerQuestion routes to cloud backend', () async {
    await prefs.setAnswerMode(AnswerMode.cloudApi);

    final answerService = AnswerServiceImpl(
      retrieval,
      _FakeLocal(),
      _FakeCloud(),
      prefs,
    );

    final result = await answerService.answerQuestion(
      document: Document(
        id: 'doc-1',
        title: 'Contract',
        extractedText: 'Payment is due within thirty days.',
        createdAt: DateTime(2026, 1, 1),
        sourceType: 'pdf',
      ),
      query: 'payment deadline',
    );

    expect(result.mode, AnswerMode.cloudApi);
    expect(result.content, contains('Cloud answer for: payment deadline'));
  });
}
