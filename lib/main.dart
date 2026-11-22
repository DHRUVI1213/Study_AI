import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'config/supabase_config.dart';
import 'core/theme/theme_notifier.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  if (SupabaseConfig.isConfigured) {
    await initializeSupabase();
  }

  // Pre-load saved theme settings
  await themeNotifier.loadTheme();

  runApp(const StudyAiApp());
}
