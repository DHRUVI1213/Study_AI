import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/flashcard_model.dart';
import '../../services/ai_service.dart';
import '../../models/document_model.dart';
import '../../services/document_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/primary_button.dart';

class FlashcardsScreen extends StatefulWidget {
  final String? documentId;

  const FlashcardsScreen({super.key, this.documentId});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  final _aiService = AiService();
  final _documentService = DocumentService();
  List<FlashcardModel> _cards = [];
  int _currentIndex = 0;
  bool _showBack = false;
  bool _isLoading = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  String? _selectedDocumentId;
  List<DocumentModel> _documents = [];
  bool _isLoadingDocs = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _selectedDocumentId = widget.documentId;
    _loadDocuments();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
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
      final data = await _aiService.generateFlashcards(
        documentId: _selectedDocumentId!,
      );
      setState(
        () => _cards = data.map((c) => FlashcardModel.fromJson(c)).toList(),
      );
    } catch (_) {
      setState(() => _cards = _demoCards());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<FlashcardModel> _demoCards() => const [
    FlashcardModel(
      id: '1',
      front: 'What is a Process?',
      back:
          'A program in execution with its own memory space, program counter, and state.',
    ),
    FlashcardModel(
      id: '2',
      front: 'What is Deadlock?',
      back:
          'A situation where two or more processes wait indefinitely for resources held by each other.',
    ),
    FlashcardModel(
      id: '3',
      front: 'Round Robin Scheduling',
      back:
          'Each process gets a fixed time quantum. After quantum expires, process moves to end of ready queue.',
    ),
    FlashcardModel(
      id: '4',
      front: 'What is Virtual Memory?',
      back:
          'Technique that gives processes the illusion of large memory by using disk as extension of RAM.',
    ),
    FlashcardModel(
      id: '5',
      front: 'What is Paging?',
      back:
          'Memory management scheme that eliminates need for contiguous allocation of physical memory.',
    ),
  ];

  void _flip() {
    if (_showBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  void _next() {
    _flipController.reset();
    setState(() {
      _showBack = false;
      _currentIndex = (_currentIndex + 1) % _cards.length;
    });
  }

  void _prev() {
    _flipController.reset();
    setState(() {
      _showBack = false;
      _currentIndex = (_currentIndex - 1 + _cards.length) % _cards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: _cards.isEmpty
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.style_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Generate Flashcards',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI will create Q&A cards from your study material',
                      style: TextStyle(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (widget.documentId == null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Study Material',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
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
                                  borderSide: BorderSide(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                  ),
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
                    PrimaryButton(
                      label: 'Generate Flashcards',
                      icon: Icons.auto_awesome_rounded,
                      isLoading: _isLoading,
                      onPressed: _generate,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_currentIndex + 1} / ${_cards.length}',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _flip,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (_, child) {
                          final angle = _flipAnimation.value * 3.14159;
                          final isUnder = _flipAnimation.value >= 0.5;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: isUnder
                                    ? AppColors.accentGradient
                                    : AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..rotateY(isUnder ? 3.14159 : 0),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isUnder ? 'ANSWER' : 'QUESTION',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        isUnder
                                            ? _cards[_currentIndex].back
                                            : _cards[_currentIndex].front,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Tap to flip',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: _prev,
                        ),
                        _NavButton(
                          icon: Icons.flip_rounded,
                          onTap: _flip,
                          isPrimary: true,
                        ),
                        _NavButton(
                          icon: Icons.arrow_forward_rounded,
                          onTap: _next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _NavButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isPrimary ? 64 : 52,
        height: isPrimary ? 64 : 52,
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.primaryGradient : null,
          color: isPrimary ? null : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: Colors.white, size: isPrimary ? 28 : 22),
      ),
    );
  }
}
