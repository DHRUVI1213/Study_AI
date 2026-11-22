import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/document_model.dart';
import '../../services/document_service.dart';
import '../../widgets/document_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_background.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => DocumentsScreenState();
}

class DocumentsScreenState extends State<DocumentsScreen> {
  final _documentService = DocumentService();
  List<DocumentModel> _documents = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final docs = await _documentService.getDocuments();
      if (mounted) setState(() => _documents = docs);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _subjects {
    final subjects = _documents
        .map((d) => d.subject)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    return ['All', ...subjects];
  }

  List<DocumentModel> get _filteredDocs {
    if (_filter == 'All') return _documents;
    return _documents.where((d) => d.subject == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Documents',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    IconButton(
                      onPressed: loadDocuments,
                      icon: const Icon(Icons.refresh_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading documents: $_error',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              if (_subjects.length > 1)
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final subject = _subjects[i];
                      final isSelected = subject == _filter;
                      return FilterChip(
                        label: Text(subject),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _filter = subject),
                        backgroundColor: AppColors.surfaceLight,
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      );
                    },
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredDocs.isEmpty
                        ? EmptyState(
                            icon: Icons.folder_open_rounded,
                            title: 'No documents yet',
                            subtitle: 'Upload your PDF notes, textbooks, or slides to get started with AI-powered study.',
                            actionLabel: 'Upload Document',
                            onAction: () async {
                              final uploaded = await context.push<bool>('/upload');
                              if (uploaded == true) loadDocuments();
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: loadDocuments,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                              itemCount: _filteredDocs.length,
                              itemBuilder: (_, i) {
                                final doc = _filteredDocs[i];
                                return DocumentTile(
                                  document: doc,
                                  onTap: () => context.push('/document/${doc.id}'),
                                  onDelete: () async {
                                    await _documentService.deleteDocument(doc.id, doc.filePath);
                                    loadDocuments();
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
