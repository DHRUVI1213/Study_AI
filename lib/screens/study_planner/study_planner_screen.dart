import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ai_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/primary_button.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  final _aiService = AiService();
  final _subjectsController = TextEditingController();
  final _hoursController = TextEditingController(text: '3');
  DateTime _examDate = DateTime.now().add(const Duration(days: 14));
  bool _isLoading = false;
  List<Map<String, dynamic>>? _schedule;

  Future<void> _generate() async {
    final subjects = _subjectsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one subject')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _aiService.generateStudyPlan(
        examDate: _examDate,
        dailyHours: double.tryParse(_hoursController.text) ?? 3,
        subjects: subjects,
      );
      final planContent = result['plan_content'] as Map<String, dynamic>? ?? {};
      setState(() => _schedule = List<Map<String, dynamic>>.from(planContent['schedule'] ?? []));
    } catch (_) {
      setState(() => _schedule = _demoSchedule(subjects));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _demoSchedule(List<String> subjects) {
    final days = _examDate.difference(DateTime.now()).inDays.clamp(3, 14);
    return List.generate(days, (i) {
      final date = DateTime.now().add(Duration(days: i + 1));
      final subject = subjects[i % subjects.length];
      return {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'focus': subject,
        'topics': [
          '$subject - Core concepts review',
          '$subject - Practice problems',
          if (i % 2 == 0) 'Revision of previous topics',
        ],
      };
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Study Planner',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Get a personalized day-by-day schedule',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, color: AppColors.primary),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text('Exam Date', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(_examDate),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ],
                      ),
                      const Spacer(),
                       Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _hoursController,
                label: 'Daily Study Hours',
                hint: 'e.g. 3',
                prefixIcon: Icons.schedule_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _subjectsController,
                label: 'Subjects (comma separated)',
                hint: 'OS, DBMS, Computer Networks',
                prefixIcon: Icons.school_rounded,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Generate Study Plan',
                icon: Icons.auto_awesome_rounded,
                isLoading: _isLoading,
                onPressed: _generate,
              ),
              if (_schedule != null) ...[
                const SizedBox(height: 32),
                Text(
                  'Your Schedule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ..._schedule!.asMap().entries.map((entry) {
                  final day = entry.value;
                  final dayNum = entry.key + 1;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'D$dayNum',
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day['focus'] as String? ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              ...(day['topics'] as List<dynamic>).map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(color: AppColors.accent)),
                                      Expanded(child: Text(t as String, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
