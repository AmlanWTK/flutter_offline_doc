import 'package:flutter_offline_ai_doc_chat/shared/models/answer_mode.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppPreferences {
  static const String _boxName = 'preferences';
  static const String _onboardingKey = 'onboarding_complete';
  static const String _answerModeKey = 'answer_mode';
  static const String _localModelPathKey = 'local_model_path';
  static const String _cloudApiBaseUrlKey = 'cloud_api_base_url';
  static const String _cloudModelKey = 'cloud_model';
  static const String _cloudApiKeyKey = 'cloud_api_key';

  static const String defaultCloudApiBaseUrl = 'https://api.openai.com/v1';
  static const String defaultCloudModel = 'gpt-4o-mini';

  static Future<void> initialize() async {
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  bool get hasCompletedOnboarding =>
      _box.get(_onboardingKey, defaultValue: false) as bool;

  Future<void> setOnboardingComplete() async {
    await _box.put(_onboardingKey, true);
  }

  Future<void> resetOnboarding() async {
    await _box.put(_onboardingKey, false);
  }

  AnswerMode get answerMode =>
      AnswerMode.fromStorage(_box.get(_answerModeKey) as String?);

  Future<void> setAnswerMode(AnswerMode mode) async {
    await _box.put(_answerModeKey, mode.name);
  }

  String? get localModelPath => _box.get(_localModelPathKey) as String?;

  Future<void> setLocalModelPath(String? path) async {
    if (path == null || path.trim().isEmpty) {
      await _box.delete(_localModelPathKey);
    } else {
      await _box.put(_localModelPathKey, path.trim());
    }
  }

  String get cloudApiBaseUrl =>
      (_box.get(_cloudApiBaseUrlKey) as String?)?.trim().isNotEmpty == true
          ? (_box.get(_cloudApiBaseUrlKey) as String).trim()
          : defaultCloudApiBaseUrl;

  Future<void> setCloudApiBaseUrl(String value) async {
    await _box.put(_cloudApiBaseUrlKey, value.trim());
  }

  String get cloudModel =>
      (_box.get(_cloudModelKey) as String?)?.trim().isNotEmpty == true
          ? (_box.get(_cloudModelKey) as String).trim()
          : defaultCloudModel;

  Future<void> setCloudModel(String value) async {
    await _box.put(_cloudModelKey, value.trim());
  }

  String? get cloudApiKey => _box.get(_cloudApiKeyKey) as String?;

  Future<void> setCloudApiKey(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _box.delete(_cloudApiKeyKey);
    } else {
      await _box.put(_cloudApiKeyKey, value.trim());
    }
  }

  bool get hasCloudApiKey =>
      cloudApiKey != null && cloudApiKey!.trim().isNotEmpty;
}
