import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_offline_ai_doc_chat/app/di/service_locator.dart';
import 'package:flutter_offline_ai_doc_chat/core/database/local_database.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/document_category.dart';
import 'package:flutter_offline_ai_doc_chat/shared/models/message.dart';
import 'package:flutter_offline_ai_doc_chat/core/storage/app_preferences.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/answer_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/export_service.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/voice_service.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final String documentId;
  const ChatScreen({super.key, required this.documentId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db = sl<LocalDatabase>();
  final _answerService = sl<AnswerService>();
  final _prefs = sl<AppPreferences>();
  final _exportService = sl<ExportService>();
  final _voiceService = sl<VoiceService>();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Message> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;
  String? _playingMessageId;

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
    final history = _db.getChatHistory(widget.documentId);
    if (history.isNotEmpty) {
      _messages.addAll(history);
    } else {
      _messages.add(Message(
        id: const Uuid().v4(),
        documentId: widget.documentId,
        content: 'Hi! Ask me anything about this document and I\'ll find the most relevant answers for you.',
        role: MessageRole.ai,
        timestamp: DateTime.now(),
      ));
    }
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      final success = await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _textController.text = text;
          });
        },
      );
      if (success) setState(() => _isListening = true);
    }
  }

  void _togglePlayMessage(String id, String content) async {
    if (_playingMessageId == id) {
      await _voiceService.stopSpeaking();
      setState(() => _playingMessageId = null);
    } else {
      await _voiceService.stopSpeaking();
      setState(() => _playingMessageId = id);
      await _voiceService.speak(content);
    }
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final userMsg = Message(
      id: const Uuid().v4(),
      documentId: widget.documentId,
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    final doc = _db.getDocument(widget.documentId);
    if (doc != null) {
      final result = await _answerService.answerQuestion(
        document: doc,
        query: text,
      );

      final aiMsg = Message(
        id: const Uuid().v4(),
        documentId: widget.documentId,
        content: result.content,
        role: MessageRole.ai,
        timestamp: DateTime.now(),
        referenceChunkIds: result.referenceChunkIds,
      );

      setState(() {
        _messages.add(aiMsg);
        _isTyping = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isTyping = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _exportChat() async {
    final doc = _db.getDocument(widget.documentId);
    if (doc == null) return;

    final ok = await _exportService.exportChatAsMarkdown(doc, _messages);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Chat exported successfully.' : 'Export failed.'),
      ),
    );
  }

  Future<void> _saveChat() async {
    await _db.saveMessages(widget.documentId, _messages);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat saved to local storage.')),
    );
  }

  void _showExportSheet() {
    final doc = _db.getDocument(widget.documentId);
    if (doc == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Export Chat',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Save or share this conversation.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
            const SizedBox(height: 20),
            _ExportOption(
              icon: Icons.chat_outlined,
              color: const Color(0xFF0077B6),
              title: 'Export Chat as Markdown',
              subtitle: 'Full conversation history (.md)',
              onTap: () {
                Navigator.pop(ctx);
                _exportChat();
              },
            ),
            const SizedBox(height: 8),
            _ExportOption(
              icon: Icons.save_outlined,
              color: const Color(0xFF2E7D32),
              title: 'Save Chat',
              subtitle: 'Save conversation to local storage',
              onTap: () {
                Navigator.pop(ctx);
                _saveChat();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doc = _db.getDocument(widget.documentId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc?.title ?? 'Chat',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            if (doc != null)
              Text(
                '${doc.category.label} · ${_prefs.answerMode.label}',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Export chat',
            onPressed: _showExportSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == MessageRole.user;
                return _ChatBubble(
                  message: msg,
                  isUser: isUser,
                  isPlaying: _playingMessageId == msg.id,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: msg.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  onPlay: () => _togglePlayMessage(msg.id, msg.content),
                );
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TypingDot(delay: 0),
                      const SizedBox(width: 4),
                      _TypingDot(delay: 150),
                      const SizedBox(width: 4),
                      _TypingDot(delay: 300),
                    ],
                  ),
                ),
              ),
            ),

          // Suggested prompts
          if (_messages.length <= 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      label: const Text('What is the summary of it?'),
                      onPressed: () {
                        _textController.text = 'What is the summary of it?';
                        _sendMessage();
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('What are the key points?'),
                      onPressed: () {
                        _textController.text = 'What are the key points?';
                        _sendMessage();
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.6),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _toggleListening,
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(Icons.arrow_upward_rounded, color: cs.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat bubble ──────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final Message message;
  final bool isUser;
  final bool isPlaying;
  final VoidCallback onCopy;
  final VoidCallback onPlay;
  
  const _ChatBubble({
    required this.message,
    required this.isUser,
    required this.isPlaying,
    required this.onCopy,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: GestureDetector(
            onLongPress: onCopy,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                      color: isUser ? cs.onPrimary : cs.onSurface,
                      fontSize: 14,
                      height: 1.5),
                ),
                if (!isUser) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onPlay,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

// ── Typing dot ───────────────────────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Export option tile ───────────────────────────────────────────────────────
class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
