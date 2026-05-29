import 'dart:convert';

import 'package:flutter_offline_ai_doc_chat/core/storage/app_preferences.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/chunk.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/rag_prompt_builder.dart';
import 'package:http/http.dart' as http;

abstract class CloudLlmService {
  Future<String> generateAnswer(String query, List<Chunk> relevantChunks);
}

class CloudLlmServiceImpl implements CloudLlmService {
  CloudLlmServiceImpl(this._prefs, {http.Client? client})
      : _client = client ?? http.Client();

  final AppPreferences _prefs;
  final http.Client _client;

  @override
  Future<String> generateAnswer(String query, List<Chunk> relevantChunks) async {
    final apiKey = _prefs.cloudApiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      return 'Cloud API is not configured. Add an API key in Settings → AI Engine.';
    }

    final baseUrl = _prefs.cloudApiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/chat/completions');

    final body = jsonEncode({
      'model': _prefs.cloudModel,
      'temperature': 0.3,
      'max_tokens': 1024,
      'messages': [
        {'role': 'system', 'content': RagPromptBuilder.systemInstruction},
        {
          'role': 'user',
          'content': RagPromptBuilder.buildUserMessage(query, relevantChunks),
        },
      ],
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _formatHttpError(response);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return 'The API returned an empty response. Check your model name and endpoint.';
      }

      final message = choices.first['message'] as Map<String, dynamic>?;
      final content = message?['content'];
      if (content is String && content.trim().isNotEmpty) {
        return content.trim();
      }

      return 'The API response did not include assistant text.';
    } on http.ClientException catch (e) {
      return 'Could not reach the API: ${e.message}. Check base URL and network.';
    } catch (e) {
      return 'Cloud request failed: $e';
    }
  }

  String _formatHttpError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final err = decoded['error'];
      if (err is Map && err['message'] is String) {
        return 'API error (${response.statusCode}): ${err['message']}';
      }
    } catch (_) {
      // Fall through to generic message.
    }
    return 'API error (${response.statusCode}): ${response.reasonPhrase ?? 'request failed'}';
  }
}
