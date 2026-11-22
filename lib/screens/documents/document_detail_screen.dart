import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/document_model.dart';
import '../../services/document_service.dart';
import '../../widgets/gradient_background.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final _documentService = DocumentService();
  DocumentModel? _document;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await _documentService.getDocument(widget.documentId);
      if (mounted) setState(() => _document = doc);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getFileIcon(String? filePath) {
    if (filePath == null) return Icons.insert_drive_file_rounded;
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
        return Icons.description_rounded;
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'txt':
        return Icons.article_rounded;
      case 'csv':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_document?.title ?? 'Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _document == null
                ? const Center(child: Text('Document not found'))
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Icon(_getFileIcon(_document!.filePath), color: Colors.white, size: 48),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _document!.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (_document!.subject != null)
                                        Text(
                                          _document!.subject!,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'AI Actions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _ActionTile(
                            icon: Icons.chat_rounded,
                            title: 'Ask AI Questions',
                            subtitle: 'Chat about this document',
                            color: AppColors.primary,
                            onTap: () => context.push('/chat?docId=${widget.documentId}'),
                          ),
                          _ActionTile(
                            icon: Icons.summarize_rounded,
                            title: 'Generate Summary',
                            subtitle: 'Short, medium, or detailed',
                            color: AppColors.accent,
                            onTap: () => context.push('/summary?docId=${widget.documentId}'),
                          ),
                          _ActionTile(
                            icon: Icons.quiz_rounded,
                            title: 'Create Quiz',
                            subtitle: 'MCQ, True/False, Short answer',
                            color: AppColors.warning,
                            onTap: () => context.push('/quiz?docId=${widget.documentId}'),
                          ),
                          _ActionTile(
                            icon: Icons.style_rounded,
                            title: 'Generate Flashcards',
                            subtitle: 'Key concepts for revision',
                            color: AppColors.accentPink,
                            onTap: () => context.push('/flashcards?docId=${widget.documentId}'),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
