import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/quiz_model.dart';
import '../../services/ai_service.dart';
import '../../models/document_model.dart';
import '../../services/document_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/primary_button.dart';

class QuizScreen extends StatefulWidget {
  final String? documentId;

  const QuizScreen({super.key, this.documentId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _aiService = AiService();
  final _documentService = DocumentService();
  String _quizType = 'mcq';
  QuizModel? _quiz;
  int _currentIndex = 0;
  int? _selectedOption;
  int _score = 0;
  bool _showResult = false;
  bool _isLoading = false;
  bool _quizStarted = false;

  String? _selectedDocumentId;
  List<DocumentModel> _documents = [];
  bool _isLoadingDocs = false;

  final _types = [
    ('mcq', 'Multiple Choice'),
    ('true_false', 'True / False'),
    ('short_answer', 'Short Answer'),
    ('descriptive', 'Descriptive'),
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
      // Ignore
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
    setState(() => _isLoading = true);
    try {
      final data = await _aiService.generateQuiz(
        documentId: _selectedDocumentId!,
        quizType: _quizType,
      );
      setState(() {
        _quiz = QuizModel.fromJson(data);
        _quizStarted = true;
      });
    } catch (_) {
      setState(() {
        _quiz = _demoQuiz();
        _quizStarted = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  QuizModel _demoQuiz() {
    return QuizModel(
      id: 'demo',
      title: 'Operating Systems Quiz',
      quizType: 'mcq',
      questions: const [
        QuizQuestion(
          question: 'Which CPU scheduling algorithm uses a time quantum?',
          options: ['FCFS', 'SJF', 'Round Robin', 'Priority'],
          correctAnswer: 'Round Robin',
          explanation:
              'Round Robin assigns a fixed time slice to each process.',
        ),
        QuizQuestion(
          question: 'What is a deadlock?',
          options: [
            'Process termination',
            'Circular wait for resources',
            'Memory overflow',
            'CPU overload',
          ],
          correctAnswer: 'Circular wait for resources',
        ),
        QuizQuestion(
          question: 'Which is NOT a necessary condition for deadlock?',
          options: [
            'Mutual Exclusion',
            'Hold and Wait',
            'Preemption',
            'Circular Wait',
          ],
          correctAnswer: 'Preemption',
        ),
      ],
    );
  }

  void _submitAnswer() {
    if (_selectedOption == null) return;
    final q = _quiz!.questions[_currentIndex];
    final selected = q.options![_selectedOption!];
    if (selected == q.correctAnswer) _score++;

    if (_currentIndex < _quiz!.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
      });
    } else {
      setState(() => _showResult = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: _showResult
            ? _buildResult()
            : !_quizStarted
            ? _buildSetup()
            : _buildQuiz(),
      ),
    );
  }

  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.documentId == null) ...[
            Text(
              'Select Study Material',
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
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'No documents found. Please upload a PDF document first.',
                      style: TextStyle(color: AppColors.error),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    initialValue: _selectedDocumentId,
                    dropdownColor: AppColors.card,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    items: _documents.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(
                          doc.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedDocumentId = val),
                  ),
            const SizedBox(height: 24),
          ],
          Text(
            'Quiz Format',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ..._types.map((t) {
            final isSelected = _quizType == t.$1;
            return ListTile(
              onTap: () => setState(() => _quizType = t.$1),
              tileColor: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              title: Text(t.$2),
            );
          }),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Generate Quiz',
            icon: Icons.quiz_rounded,
            isLoading: _isLoading,
            onPressed: _generate,
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final q = _quiz!.questions[_currentIndex];
    final progress = (_currentIndex + 1) / _quiz!.questions.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${_currentIndex + 1}/${_quiz!.questions.length}'),
              Text(
                'Score: $_score',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceLight,
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 32),
          Text(
            q.question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.builder(
              itemCount: q.options?.length ?? 0,
              itemBuilder: (_, i) {
                final isSelected = _selectedOption == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedOption = i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceLight,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(q.options![i])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          PrimaryButton(
            label: _currentIndex < _quiz!.questions.length - 1
                ? 'Next Question'
                : 'Finish Quiz',
            onPressed: _selectedOption != null ? _submitAnswer : null,
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final total = _quiz!.questions.length;
    final percent = ((_score / total) * 100).round();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: percent >= 70
                    ? AppColors.accentGradient
                    : AppColors.warmGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              percent >= 70 ? 'Great job!' : 'Keep practicing!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'You scored $_score out of $total',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Try Again',
              onPressed: () => setState(() {
                _showResult = false;
                _quizStarted = false;
                _currentIndex = 0;
                _score = 0;
                _selectedOption = null;
                _quiz = null;
              }),
            ),
          ],
        ),
      ),
    );
  }
}
