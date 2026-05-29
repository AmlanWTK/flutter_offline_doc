import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_offline_ai_doc_chat/core/storage/app_preferences.dart';
import 'package:flutter_offline_ai_doc_chat/core/utils/platform_utils.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/chunk.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/rag_prompt_builder.dart';
import 'package:llamadart/llamadart.dart';

abstract class LocalLlmService {
  bool get isModelLoaded;
  String? get loadedModelPath;
  Future<String> generateAnswer(String query, List<Chunk> relevantChunks);
  Future<String?> loadModelFromPreferences();
  void dispose();
}

class LocalLlmServiceImpl implements LocalLlmService {
  LocalLlmServiceImpl(this._prefs);

  final AppPreferences _prefs;
  final LlamaService _service = LlamaService();

  bool _loaded = false;
  String? _loadedPath;

  @override
  bool get isModelLoaded => _loaded && _service.isReady;

  @override
  String? get loadedModelPath => _loadedPath;

  @override
  Future<String?> loadModelFromPreferences() async {
    if (!supportsLocalLlm) {
      return 'Local LLM is not supported on this platform.';
    }

    final path = _prefs.localModelPath?.trim();
    if (path == null || path.isEmpty) {
      return 'Pick a GGUF model file in Settings → AI Engine → Local LLM.';
    }

    if (path.startsWith('http')) {
      try {
        await _service.initFromUrl(
          path,
          modelParams: const ModelParams(gpuLayers: 99),
        );
      } catch (e) {
        return 'Failed to load model from URL: $e';
      }
    } else {
      if (!kIsWeb && !File(path).existsSync()) {
        return 'Model file not found:\n$path';
      }
      try {
        await _service.init(
          path,
          modelParams: const ModelParams(gpuLayers: 99),
        );
      } catch (e) {
        return 'Failed to load model: $e';
      }
    }

    _loaded = true;
    _loadedPath = path;
    return null;
  }

  Future<void> _ensureLoaded() async {
    if (isModelLoaded) return;
    final error = await loadModelFromPreferences();
    if (error != null) {
      throw LocalLlmException(error);
    }
  }

  @override
  Future<String> generateAnswer(String query, List<Chunk> relevantChunks) async {
    if (!supportsLocalLlm) {
      return 'Local LLM requires Android, iOS, or desktop (not web). '
          'Switch to Keyword excerpts or Cloud API in Settings.';
    }

    try {
      await _ensureLoaded();
    } on LocalLlmException catch (e) {
      return e.message;
    }

    final messages = [
      const LlamaChatMessage(
        role: 'system',
        content: RagPromptBuilder.systemInstruction,
      ),
      LlamaChatMessage(
        role: 'user',
        content: RagPromptBuilder.buildUserMessage(query, relevantChunks),
      ),
    ];

    final prompt = await _service.applyChatTemplate(messages);
    final buffer = StringBuffer();

    try {
      await for (final token in _service.generate(
        prompt,
        params: const GenerationParams(
          maxTokens: 512,
          temp: 0.3,
          topK: 40,
          topP: 0.9,
          penalty: 1.1,
        ),
      )) {
        buffer.write(token);
      }
    } catch (e) {
      return 'Local generation failed: $e';
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      return 'The model returned an empty answer. Try a smaller GGUF quant or another model.';
    }
    return _stripLeakage(text);
  }

  String _stripLeakage(String text) {
    const markers = [
      '<|user|>',
      '<|assistant|>',
      '<|im_start|>',
      '<|im_end|>',
      '<|end_of_turn|>',
      '<|eot_id|>',
    ];
    var cleaned = text;
    for (final marker in markers) {
      cleaned = cleaned.replaceAll(marker, '');
    }
    return cleaned.trim();
  }

  @override
  void dispose() {
    _service.dispose();
    _loaded = false;
    _loadedPath = null;
  }
}

class LocalLlmException implements Exception {
  LocalLlmException(this.message);
  final String message;

  @override
  String toString() => message;
}
