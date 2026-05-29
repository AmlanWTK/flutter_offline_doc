import 'package:flutter_offline_ai_doc_chat/core/storage/app_preferences.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/answer_mode.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/cloud_llm_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/local_llm_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/retrieval_service.dart';

class DocumentAnswer {
  const DocumentAnswer({
    required this.content,
    required this.referenceChunkIds,
    required this.mode,
  });

  final String content;
  final List<String> referenceChunkIds;
  final AnswerMode mode;
}

abstract class AnswerService {
  Future<DocumentAnswer> answerQuestion({
    required Document document,
    required String query,
  });
}

class AnswerServiceImpl implements AnswerService {
  AnswerServiceImpl(
    this._retrieval,
    this._localLlm,
    this._cloudLlm,
    this._prefs,
  );

  final RetrievalService _retrieval;
  final LocalLlmService _localLlm;
  final CloudLlmService _cloudLlm;
  final AppPreferences _prefs;

  @override
  Future<DocumentAnswer> answerQuestion({
    required Document document,
    required String query,
  }) async {
    final chunks = _retrieval.chunkDocument(document);
    final relevantChunks = _retrieval.searchRelevantChunks(query, chunks);
    final mode = _prefs.answerMode;

    final String content;
    switch (mode) {
      case AnswerMode.excerpts:
        content = await _retrieval.generateAnswer(query, relevantChunks);
      case AnswerMode.localLlm:
        content = await _localLlm.generateAnswer(query, relevantChunks);
      case AnswerMode.cloudApi:
        content = await _cloudLlm.generateAnswer(query, relevantChunks);
    }

    return DocumentAnswer(
      content: content,
      referenceChunkIds: relevantChunks.map((c) => c.id).toList(),
      mode: mode,
    );
  }
}
