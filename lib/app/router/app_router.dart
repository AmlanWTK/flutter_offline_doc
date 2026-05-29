import 'package:go_router/go_router.dart';
import 'package:flutter_offline_ai_doc_chat/app/di/service_locator.dart';
import 'package:flutter_offline_ai_doc_chat/core/storage/app_preferences.dart';
import 'package:flutter_offline_ai_doc_chat/features/onboarding/onboarding_screen.dart';
import 'package:flutter_offline_ai_doc_chat/features/settings/settings_screen.dart';
import 'package:flutter_offline_ai_doc_chat/features/document_capture/document_capture_screen.dart';
import 'package:flutter_offline_ai_doc_chat/features/document_library/library_screen.dart';
import 'package:flutter_offline_ai_doc_chat/features/document_library/document_detail_screen.dart';
import 'package:flutter_offline_ai_doc_chat/features/document_chat/chat_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final prefs = sl<AppPreferences>();
      final onOnboarding = state.matchedLocation == '/onboarding';

      if (!prefs.hasCompletedOnboarding && !onOnboarding) {
        return '/onboarding';
      }
      if (prefs.hasCompletedOnboarding && onOnboarding) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) => const DocumentCaptureScreen(),
      ),
      GoRoute(
        path: '/document/:id',
        builder: (context, state) => DocumentDetailScreen(
          documentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatScreen(
          documentId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
}
