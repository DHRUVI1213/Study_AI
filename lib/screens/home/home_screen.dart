import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../models/document_model.dart';
import '../../services/auth_service.dart';
import '../../services/document_service.dart';
import '../../widgets/document_tile.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _documentService = DocumentService();
  List<DocumentModel> _documents = [];
  int _quizCount = 0;
  int _flashcardCount = 0;
  double _studyHours = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      
      if (userId != null) {
        // Fetch documents
        final docs = await _documentService.getDocuments();
        
        // Fetch quizzes count
        final quizzes = await client
            .from('quizzes')
            .select('id');
            
        // Fetch flashcards count
        final flashcards = await client
            .from('flashcards')
            .select('id');
            
        // Fetch study plans daily hours
        final studyPlans = await client
            .from('study_plans')
            .select('daily_hours');
            
        double hours = 0.0;
        for (final plan in studyPlans) {
          hours += (plan['daily_hours'] as num?)?.toDouble() ?? 0.0;
        }

        if (mounted) {
          setState(() {
            _documents = docs;
            _quizCount = quizzes.length;
            _flashcardCount = flashcards.length;
            _studyHours = hours;
          });
        }
      }
    } catch (_) {
      // Keep UI usable if fetch fails
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openUpload() async {
    final uploaded = await context.push<bool>('/upload');
    if (uploaded == true) loadData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final name = auth.userDisplayName ?? 'Student';
    final docCount = _documents.length.toString();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: loadData,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, $name 👋',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ready to study smarter today?',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: loadData,
                              icon: const Icon(Icons.refresh_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surfaceLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upload & Learn',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload your notes and let AI help you revise faster.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _openUpload,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.upload_file_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text('Upload PDF', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        const SectionHeader(title: 'Your Progress'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                label: 'Documents',
                                value: _isLoading ? '...' : docCount,
                                icon: Icons.folder_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                label: 'Quizzes',
                                value: _isLoading ? '...' : _quizCount.toString(),
                                icon: Icons.quiz_rounded,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                label: 'Flashcards',
                                value: _isLoading ? '...' : _flashcardCount.toString(),
                                icon: Icons.style_rounded,
                                color: AppColors.accentPink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                label: 'Study Hours',
                                value: _isLoading ? '...' : (_studyHours == _studyHours.toInt() 
                                    ? '${_studyHours.toInt()}h' 
                                    : '${_studyHours.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}h'),
                                icon: Icons.timer_rounded,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        if (_documents.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          SectionHeader(
                            title: 'Recent Documents',
                            actionLabel: 'See all',
                            onAction: () async {
                              await context.push('/documents');
                              loadData();
                            },
                          ),
                          const SizedBox(height: 8),
                          ..._documents.take(3).map(
                                (doc) => DocumentTile(
                                  document: doc,
                                  onTap: () async {
                                    await context.push('/document/${doc.id}');
                                    loadData();
                                  },
                                ),
                              ),
                        ],
                        const SizedBox(height: 28),
                        const SectionHeader(title: 'AI Tools'),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 150,
                    ),
                    delegate: SliverChildListDelegate([
                      FeatureCard(
                        title: 'AI Chat',
                        subtitle: 'Ask doubts from your notes',
                        icon: Icons.chat_bubble_rounded,
                        gradient: AppColors.primaryGradient,
                        onTap: () async {
                          await context.push('/chat');
                          loadData();
                        },
                      ),
                      FeatureCard(
                        title: 'Summaries',
                        subtitle: 'Quick revision notes',
                        icon: Icons.summarize_rounded,
                        gradient: AppColors.accentGradient,
                        onTap: () async {
                          await context.push('/summary');
                          loadData();
                        },
                      ),
                      FeatureCard(
                        title: 'Quiz',
                        subtitle: 'Test your knowledge',
                        icon: Icons.quiz_rounded,
                        gradient: AppColors.warmGradient,
                        onTap: () async {
                          await context.push('/quiz');
                          loadData();
                        },
                      ),
                      FeatureCard(
                        title: 'Flashcards',
                        subtitle: 'Memorize key concepts',
                        icon: Icons.style_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                        ),
                        onTap: () async {
                          await context.push('/flashcards');
                          loadData();
                        },
                      ),
                      FeatureCard(
                        title: 'Study Plan',
                        subtitle: 'Plan your exam prep',
                        icon: Icons.calendar_month_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                        ),
                        onTap: () async {
                          await context.push('/study-planner');
                          loadData();
                        },
                      ),
                      FeatureCard(
                        title: 'Documents',
                        subtitle: 'Manage your files',
                        icon: Icons.folder_open_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                        ),
                        onTap: () async {
                          await context.push('/documents');
                          loadData();
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
