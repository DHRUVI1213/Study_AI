import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_notifier.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/gradient_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _aiService = AiService();
  late String _name;
  late String _email;
  bool _isUpdatingName = false;

  @override
  void initState() {
    super.initState();
    _name = _auth.userDisplayName ?? 'Student';
    _email = _auth.userEmail ?? 'demo@student.edu';
  }

  void _showEditProfile() {
    final screenContext = context;
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: Text(
            'Edit Profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Leave blank to keep current',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                final newEmail = emailController.text.trim();
                final newPassword = passwordController.text;

                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name cannot be empty')),
                  );
                  return;
                }
                if (newEmail.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email cannot be empty')),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => _isUpdatingName = true);

                try {
                  List<String> updates = [];

                  if (newName != _name) {
                    await _auth.updateDisplayName(newName);
                    _name = newName;
                    updates.add('name');
                  }

                  if (newEmail != _email) {
                    await _auth.updateEmail(newEmail);
                    _email = newEmail;
                    updates.add('email change requested');
                  }

                  if (newPassword.isNotEmpty) {
                    if (newPassword.length < 6) {
                      throw Exception('Password must be at least 6 characters');
                    }
                    await _auth.updatePassword(newPassword);
                    updates.add('password');
                  }

                  if (!screenContext.mounted) return;
                  setState(() {
                    _isUpdatingName = false;
                  });

                  if (updates.isEmpty) {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      const SnackBar(content: Text('No changes made')),
                    );
                  } else {
                    String msg = 'Updated: ${updates.join(", ")}';
                    if (updates.contains('email change requested')) {
                      msg +=
                          '. Please confirm on both email addresses to apply the change.';
                    }
                    ScaffoldMessenger.of(
                      screenContext,
                    ).showSnackBar(SnackBar(content: Text(msg)));
                  }
                } catch (e) {
                  if (!screenContext.mounted) return;
                  setState(() => _isUpdatingName = false);
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    SnackBar(content: Text('Failed to update profile: $e')),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FutureBuilder<List<Map<String, dynamic>>>(
          future: _aiService.getChatSessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              );
            }
            final sessions = snapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.all(24),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: sessions.isEmpty
                        ? Center(
                            child: Text(
                              'No chat history yet.\nStart chatting inside your documents!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              final docMap =
                                  session['documents'] as Map<String, dynamic>?;
                              final docTitle =
                                  docMap?['title'] as String? ?? 'General Chat';
                              final title =
                                  session['title'] as String? ?? 'Chat Session';
                              final dateStr = session['created_at'] != null
                                  ? DateFormat('MMM d, yyyy · h:mm a').format(
                                      DateTime.parse(
                                        session['created_at'] as String,
                                      ),
                                    )
                                  : '';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    title,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$docTitle · $dateStr',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.push(
                                      '/chat?docId=${session['document_id']}&sessionId=${session['id']}',
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSavedSummaries() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _aiService.getSavedSummaries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            );
          }
          final summaries = snapshot.data ?? [];
          return Container(
            padding: const EdgeInsets.all(24),
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Summaries',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: summaries.isEmpty
                      ? Center(
                          child: Text(
                            'No summaries generated yet.\nGenerate one from the Documents tab!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: summaries.length,
                          itemBuilder: (context, index) {
                            final summary = summaries[index];
                            final docMap =
                                summary['documents'] as Map<String, dynamic>?;
                            final docTitle =
                                docMap?['title'] as String? ?? 'Document';
                            final type =
                                (summary['summary_type'] as String? ?? 'medium')
                                    .toUpperCase();
                            final dateStr = summary['created_at'] != null
                                ? DateFormat('MMM d, yyyy').format(
                                    DateTime.parse(
                                      summary['created_at'] as String,
                                    ),
                                  )
                                : '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: ListTile(
                                title: Text(
                                  docTitle,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '$type Summary · $dateStr',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chrome_reader_mode_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _viewSummaryDetail(
                                    docTitle,
                                    type,
                                    summary['content'] as String,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _viewSummaryDetail(
    String docTitle,
    String type,
    String markdownContent,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              docTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$type Summary',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: markdownContent,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    h1: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    listBullet: const TextStyle(color: AppColors.primary),
                  ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    final screenContext = context;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: Text(
            'Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: themeNotifier.isDarkMode,
                title: Text(
                  'Dark Mode',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  themeNotifier.isDarkMode
                      ? 'Enable light theme'
                      : 'Enable dark theme',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                secondary: Icon(
                  themeNotifier.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: AppColors.primary,
                ),
                activeThumbColor: AppColors.primary,
                onChanged: (value) async {
                  await themeNotifier.toggleTheme();
                  setStateDialog(() {});
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.delete_sweep_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  'Clear Offline Cache',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  'Removes all offline summaries & quizzes.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!screenContext.mounted) return;
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    const SnackBar(
                      content: Text('Offline cache cleared successfully'),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How do I upload notes?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Go to the Docs tab and click the "+" or "Upload" button to pick a PDF. Extracted text will automatically process.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 16),
              Text(
                'How does offline caching work?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Summaries, quizzes, and flashcards are automatically saved locally when generated online. You can view them later without network requests.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 16),
              Text(
                'Contact Us',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'For queries, email support@studyai.edu.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: _isUpdatingName
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _name.isNotEmpty ? _name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        _email,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 36),
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profile',
                        onTap: _showEditProfile,
                      ),
                      _MenuItem(
                        icon: Icons.history_rounded,
                        title: 'Chat History',
                        onTap: _showChatHistory,
                      ),
                      _MenuItem(
                        icon: Icons.bookmark_rounded,
                        title: 'Saved Summaries',
                        onTap: _showSavedSummaries,
                      ),
                      _MenuItem(
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        onTap: _showSettings,
                      ),
                      _MenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: _showHelpSupport,
                      ),
                      const SizedBox(height: 16),
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        color: AppColors.error,
                        onTap: () async {
                          await _auth.signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'StudyAI v1.0.0',
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                          fontSize: 12,
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color ?? AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
