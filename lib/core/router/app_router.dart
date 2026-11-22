import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_notifier.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../screens/home/main_shell.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/documents/documents_screen.dart';
import '../../screens/documents/upload_document_screen.dart';
import '../../screens/documents/document_detail_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/summary/summary_screen.dart';
import '../../screens/quiz/quiz_screen.dart';
import '../../screens/flashcards/flashcards_screen.dart';
import '../../screens/study_planner/study_planner_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static const _publicRoutes = {
    '/',
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
  };

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loggedIn = authNotifier.isLoggedIn;
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      // Password recovery must take priority over normal authenticated
      // navigation. Recovery sessions must not enter the dashboard.
      if (authNotifier.isPasswordRecovery) {
        if (location != '/reset-password') {
          return '/reset-password';
        }
        return null;
      }

      // Splash handles its own navigation
      if (location == '/') return null;

      if (loggedIn && (location == '/login' || location == '/register')) {
        return '/home';
      }

      if (!loggedIn && !isPublic) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/study-planner',
                builder: (context, state) => const StudyPlannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                builder: (context, state) => const DocumentsScreen(),
              ),
              GoRoute(
                path: '/upload',
                builder: (context, state) => const UploadDocumentScreen(),
              ),
              GoRoute(
                path: '/document/:id',
                builder: (context, state) => DocumentDetailScreen(
                  documentId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: '/summary',
                builder: (context, state) => SummaryScreen(
                  documentId: state.uri.queryParameters['docId'],
                ),
              ),
              GoRoute(
                path: '/quiz',
                builder: (context, state) =>
                    QuizScreen(documentId: state.uri.queryParameters['docId']),
              ),
              GoRoute(
                path: '/flashcards',
                builder: (context, state) => FlashcardsScreen(
                  documentId: state.uri.queryParameters['docId'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => ChatScreen(
                  documentId: state.uri.queryParameters['docId'],
                  sessionId: state.uri.queryParameters['sessionId'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
