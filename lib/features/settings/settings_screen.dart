import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_offline_ai_doc_chat/app/di/service_locator.dart';
import 'package:flutter_offline_ai_doc_chat/core/database/local_database.dart';
import 'package:flutter_offline_ai_doc_chat/core/storage/app_preferences.dart';
import 'package:flutter_offline_ai_doc_chat/core/utils/platform_utils.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/storage_stats.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = sl<LocalDatabase>();
  final _prefs = sl<AppPreferences>();

  StorageStats? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
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
            subtitle: const Text('All documents stay on this device'),
            trailing: Switch.adaptive(value: true, onChanged: null),
          ),
          if (!supportsOcrCapture)
            ListTile(
              leading: Icon(Icons.info_outline, color: cs.tertiary),
              title: const Text('Desktop mode'),
              subtitle: const Text(
                'OCR runs on Android/iOS. On desktop, import pre-extracted text via images where supported.',
              ),
            ),
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
          _SectionHeader(title: 'AI Engine'),
          const ListTile(
            leading: Icon(Icons.search),
            title: Text('Keyword Retrieval'),
            subtitle: Text('Offline chunk search with extractive answers'),
            trailing: Icon(Icons.check, color: Colors.green),
          ),
          ListTile(
            leading: const Icon(Icons.model_training_outlined),
            title: const Text('Local LLM (Roadmap)'),
            subtitle: const Text('Planned for a future release'),
            enabled: false,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Cloud AI Provider (Roadmap)'),
            subtitle: const Text('Optional API key support coming later'),
            enabled: false,
            onTap: () {},
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
