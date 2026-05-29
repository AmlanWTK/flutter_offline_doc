import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline_ai_doc_chat/app/di/service_locator.dart';
import 'package:flutter_offline_ai_doc_chat/core/database/local_database.dart';
import 'package:flutter_offline_ai_doc_chat/core/storage/app_preferences.dart';
import 'package:flutter_offline_ai_doc_chat/core/utils/platform_utils.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/answer_mode.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/storage_stats.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/local_llm_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = sl<LocalDatabase>();
  final _prefs = sl<AppPreferences>();
  final _localLlm = sl<LocalLlmService>();

  final _cloudBaseUrlController = TextEditingController();
  final _cloudModelController = TextEditingController();
  final _cloudApiKeyController = TextEditingController();

  StorageStats? _stats;
  bool _loadingStats = true;
  bool _loadingModel = false;
  String? _localModelStatus;

  AnswerMode _answerMode = AnswerMode.excerpts;
  String? _localModelPath;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadStats();
  }

  void _loadPrefs() {
    _answerMode = _prefs.answerMode;
    _localModelPath = _prefs.localModelPath;
    _cloudBaseUrlController.text = _prefs.cloudApiBaseUrl;
    _cloudModelController.text = _prefs.cloudModel;
    _cloudApiKeyController.text = _prefs.cloudApiKey ?? '';
    _localModelStatus = _localLlm.isModelLoaded
        ? 'Loaded: ${_localLlm.loadedModelPath}'
        : null;
  }

  @override
  void dispose() {
    _cloudBaseUrlController.dispose();
    _cloudModelController.dispose();
    _cloudApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    final stats = await _db.getStorageStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    }
  }

  Future<void> _saveCloudSettings() async {
    await _prefs.setCloudApiBaseUrl(_cloudBaseUrlController.text);
    await _prefs.setCloudModel(_cloudModelController.text);
    await _prefs.setCloudApiKey(_cloudApiKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud API settings saved.')),
      );
    }
  }

  Future<void> _pickGgufModel() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Select a GGUF model',
      type: FileType.custom,
      allowedExtensions: const ['gguf'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    await _prefs.setLocalModelPath(path);
    _localLlm.dispose();
    setState(() {
      _localModelPath = path;
      _localModelStatus = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model path saved. Tap Load model when ready.')),
      );
    }
  }

  Future<void> _loadLocalModel() async {
    setState(() {
      _loadingModel = true;
      _localModelStatus = 'Loading model…';
    });

    _localLlm.dispose();
    final error = await _localLlm.loadModelFromPreferences();

    if (!mounted) return;
    setState(() {
      _loadingModel = false;
      _localModelStatus =
          error ?? 'Model loaded. First reply may take a minute.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Local model ready.'),
      ),
    );
  }

  Future<void> _setAnswerMode(AnswerMode mode) async {
    await _prefs.setAnswerMode(mode);
    setState(() => _answerMode = mode);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all saved documents and extracted text. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _db.clearAllDocuments();
    await _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All documents cleared.')),
      );
    }
  }

  Future<void> _resetOnboarding() async {
    await _prefs.resetOnboarding();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding will show on next launch.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Privacy'),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Privacy Mode'),
            subtitle: const Text('Documents stay on device unless you use Cloud API'),
            trailing: Switch.adaptive(value: true, onChanged: null),
          ),
          if (!supportsOcrCapture)
            ListTile(
              leading: Icon(Icons.info_outline, color: cs.tertiary),
              title: const Text('Desktop mode'),
              subtitle: const Text(
                'OCR runs on Android/iOS. On desktop, import PDFs or images where supported.',
              ),
            ),
          const Divider(height: 32),
          _SectionHeader(title: 'AI Engine'),
          ...AnswerMode.values.map((mode) {
            final selected = _answerMode == mode;
            final disabled = mode == AnswerMode.localLlm && !supportsLocalLlm;
            return RadioListTile<AnswerMode>(
              value: mode,
              groupValue: _answerMode,
              onChanged: disabled
                  ? null
                  : (value) {
                      if (value != null) _setAnswerMode(value);
                    },
              title: Text(mode.label),
              subtitle: Text(
                disabled
                    ? '${mode.subtitle} (not available on web)'
                    : mode.subtitle,
              ),
              secondary: selected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            );
          }),
          if (_answerMode == AnswerMode.localLlm && supportsLocalLlm) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Download a small GGUF (e.g. TinyLlama Q4_K_M, ~700 MB) and pick it below. '
                'Android requires API 29+ and arm64/x86_64.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('GGUF model file'),
              subtitle: Text(
                _localModelPath ?? 'No model selected',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickGgufModel,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: FilledButton.icon(
                onPressed: _loadingModel ? null : _loadLocalModel,
                icon: _loadingModel
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.memory_outlined),
                label: Text(_loadingModel ? 'Loading…' : 'Load model into memory'),
              ),
            ),
            if (_localModelStatus != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  _localModelStatus!,
                  style: TextStyle(fontSize: 12, color: cs.primary),
                ),
              ),
          ],
          if (_answerMode == AnswerMode.cloudApi) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Uses an OpenAI-compatible /v1/chat/completions endpoint. '
                'Document excerpts are sent with each question.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _cloudBaseUrlController,
                decoration: const InputDecoration(
                  labelText: 'API base URL',
                  hintText: 'https://api.openai.com/v1',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _cloudModelController,
                decoration: const InputDecoration(
                  labelText: 'Model name',
                  hintText: 'gpt-4o-mini',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _cloudApiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API key',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _saveCloudSettings,
                child: const Text('Save cloud settings'),
              ),
            ),
          ],
          const Divider(height: 32),
          _SectionHeader(title: 'Storage'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Local storage'),
            subtitle: _loadingStats
                ? const Text('Calculating...')
                : Text(
                    '${_stats?.documentCount ?? 0} documents · '
                    '${_stats?.formattedTotal ?? '0 B'} used',
                  ),
            onTap: _loadStats,
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: cs.error),
            title: Text('Clear all documents', style: TextStyle(color: cs.error)),
            subtitle: const Text('Remove every saved document from this device'),
            onTap: _clearAllData,
          ),
          const Divider(height: 32),
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.restart_alt_outlined),
            title: const Text('Show onboarding again'),
            subtitle: const Text('Reset the first-run welcome screens'),
            onTap: _resetOnboarding,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text('1.0.0 · ${Platform.operatingSystem}'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
