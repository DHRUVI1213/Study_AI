import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/document_model.dart';
import '../../services/ai_service.dart';
import '../../services/document_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/primary_button.dart';

class SummaryScreen extends StatefulWidget {
  final String? documentId;

  const SummaryScreen({super.key, this.documentId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _aiService = AiService();
  final _documentService = DocumentService();
  String _selectedType = 'short';
  String? _summary;
  bool _isLoading = false;

  String? _selectedDocumentId;
  List<DocumentModel> _documents = [];
  bool _isLoadingDocs = false;

  final _types = [
    ('short', 'Short', 'Key bullet points', Icons.format_list_bulleted_rounded),
    ('medium', 'Medium', 'Chapter-wise overview', Icons.article_rounded),
    ('detailed', 'Detailed', 'Full revision notes', Icons.menu_book_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDocumentId = widget.documentId;
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoadingDocs = true);
    try {
      final docs = await _documentService.getDocuments();
      setState(() {
        _documents = docs;
        if (_selectedDocumentId == null && docs.isNotEmpty) {
          _selectedDocumentId = docs.first.id;
        }
      });
    } catch (_) {
      // Ignore or handle
    } finally {
      setState(() => _isLoadingDocs = false);
    }
  }

  Future<void> _generate() async {
    if (_selectedDocumentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or upload a document first'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _summary = null;
    });

    try {
      final result = await _aiService.generateSummary(
        documentId: _selectedDocumentId!,
        summaryType: _selectedType,
      );
      setState(() => _summary = result);
    } catch (_) {
      setState(() => _summary = _demoSummary(_selectedType));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _demoSummary(String type) {
    return switch (type) {
      'short' =>
        '''## Key Points
- **Process Management**: Creation, scheduling, termination of processes
- **CPU Scheduling**: FCFS, SJF, Round Robin, Priority scheduling
- **Deadlocks**: Conditions, prevention, avoidance, detection
- **Memory Management**: Paging, segmentation, virtual memory''',
      'medium' =>
        '''## Chapter Overview

### 1. Process Management
Processes are programs in execution. The OS manages process creation using fork/exec, scheduling via various algorithms, and termination.

### 2. CPU Scheduling
Algorithms like Round Robin ensure fair CPU time distribution among processes.

### 3. Deadlocks
Occur when processes wait indefinitely for resources held by each other.''',
      _ =>
        '''## Comprehensive Revision Notes

### Process Management
A process is an instance of a program in execution. The operating system uses a Process Control Block (PCB) to store process state, program counter, CPU registers, and memory management information.

### CPU Scheduling Algorithms
1. **FCFS** - First Come First Served, simple but may cause convoy effect
2. **SJF** - Shortest Job First, optimal for minimizing wait time
3. **Round Robin** - Time quantum based, fair for interactive systems
4. **Priority** - Higher priority processes served first

### Deadlock
Four necessary conditions: Mutual Exclusion, Hold and Wait, No Preemption, Circular Wait.''',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Document',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _isLoadingDocs
                  ? const Center(child: CircularProgressIndicator())
                  : _documents.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.error),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No documents available. Please upload a document first.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue:
                          _documents.any((doc) => doc.id == _selectedDocumentId)
                          ? _selectedDocumentId
                          : null,
                      hint: const Text('Choose a document'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
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
                        setState(() {
                          _selectedDocumentId = val;
                          _summary = null; // Clear previous summary
                        });
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.description_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
              Text(
                'Choose Summary Type',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ..._types.map((t) {
                final (id, title, desc, icon) = t;
                final isSelected = _selectedType == id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                desc,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Generate Summary',
                icon: Icons.auto_awesome_rounded,
                isLoading: _isLoading,
                onPressed: _generate,
              ),
              if (_summary != null) ...[
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: MarkdownBody(
                    data: _summary!,
                    styleSheet: MarkdownStyleSheet(
                      h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryLight,
                      ),
                      p: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.6),
                      listBullet: const TextStyle(color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
