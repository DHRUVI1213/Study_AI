import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_message_model.dart';
import '../../models/document_model.dart';
import '../../services/ai_service.dart';
import '../../services/document_service.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/gradient_background.dart';

class ChatScreen extends StatefulWidget {
  final String? documentId;
  final String? sessionId;

  const ChatScreen({super.key, this.documentId, this.sessionId});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _aiService = AiService();
  final _documentService = DocumentService();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  final List<ChatMessageModel> _messages = [];
  String? _sessionId;
  bool _isLoading = false;

  String? _selectedDocumentId;
  List<DocumentModel> _documents = [];
  bool _isLoadingDocs = false;

  final _suggestions = [
    'Explain the key concepts',
    'What are the important topics?',
    'Summarize this in simple terms',
    'Give me exam tips for this subject',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDocumentId = widget.documentId;
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    setState(() => _isLoadingDocs = true);
    try {
      final docs = await _documentService.getDocuments();
      setState(() {
        _documents = docs;
        if (_selectedDocumentId == null && docs.isNotEmpty) {
          _selectedDocumentId = docs.first.id;
        }
      });
      await _initSession();
    } catch (_) {
      await _initSession();
    } finally {
      if (mounted) setState(() => _isLoadingDocs = false);
    }
  }

  Future<void> _initSession() async {
    setState(() => _isLoading = true);
    try {
      if (widget.sessionId != null) {
        _sessionId = widget.sessionId;
        final history = await _aiService.getChatMessages(widget.sessionId!);
        setState(() {
          _messages.clear();
          _messages.addAll(history);
        });
      } else {
        String? activeTitle;
        if (_selectedDocumentId != null && _documents.isNotEmpty) {
          final matched = _documents.where((d) => d.id == _selectedDocumentId);
          if (matched.isNotEmpty) {
            activeTitle = 'Chat: ${matched.first.title}';
          }
        }
        _sessionId = await _aiService.createChatSession(
          documentId: _selectedDocumentId,
          title: activeTitle,
        );
      }
    } catch (_) {
      _sessionId = widget.sessionId ?? 'demo-session';
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage([String? text]) async {
    final message = text ?? _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    _focusNode.requestFocus();
    setState(() {
      _messages.add(
        ChatMessageModel(
          id: DateTime.now().toString(),
          sessionId: _sessionId ?? '',
          role: 'user',
          content: message,
          createdAt: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _aiService.chat(
        sessionId: _sessionId ?? 'demo',
        message: message,
        documentId: _selectedDocumentId,
      );
      setState(() {
        _messages.add(
          ChatMessageModel(
            id: DateTime.now().toString(),
            sessionId: _sessionId ?? '',
            role: 'assistant',
            content: reply,
            createdAt: DateTime.now(),
          ),
        );
      });
    } catch (_) {
      setState(() {
        _messages.add(
          ChatMessageModel(
            id: DateTime.now().toString(),
            sessionId: _sessionId ?? '',
            role: 'assistant',
            content:
                '**Demo Mode**: Connect Supabase Edge Functions to enable AI chat.\n\nYour question: "$message"\n\nOnce configured, I\'ll answer based on your uploaded study materials using Gemini AI.',
            createdAt: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.documentId != null;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('AI Tutor'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (!showAppBar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Tutor',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Ask anything about your notes',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              _isLoadingDocs
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _documents.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.error),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No documents uploaded. Upload a document to start a conversation.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            _documents.any(
                              (doc) => doc.id == _selectedDocumentId,
                            )
                            ? _selectedDocumentId
                            : null,
                        hint: const Text('Select a document to chat about'),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        dropdownColor: AppColors.surfaceLight,
                        items: _documents.map((doc) {
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(
                              doc.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != _selectedDocumentId) {
                            setState(() {
                              _selectedDocumentId = val;
                              _messages.clear();
                            });
                            _initSession();
                          }
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.description_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _messages.length && _isLoading) {
                            return const ChatBubble(
                              message: '',
                              isUser: false,
                              isLoading: true,
                            );
                          }
                          final msg = _messages[i];
                          return ChatBubble(
                            message: msg.content,
                            isUser: msg.isUser,
                          );
                        },
                      ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How can I help you study?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask questions about your uploaded materials',
              style: TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 13)),
                  backgroundColor: AppColors.card,
                  side: BorderSide(color: AppColors.cardBorder),
                  onPressed: () => _sendMessage(s),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              style: TextStyle(color: AppColors.textPrimary),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: _isLoading ? null : () => _sendMessage(),
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
