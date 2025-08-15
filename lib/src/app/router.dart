import 'package:go_router/go_router.dart';
import 'package:teditox/src/features/editor/presentation/editor_screen.dart';
import 'package:teditox/src/features/recent/presentation/recent_screen.dart';
import 'package:teditox/src/features/settings/presentation/about_screen.dart';
import 'package:teditox/src/features/settings/presentation/settings_screen.dart';

/// Builds the application router with defined routes.
GoRouter buildRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'editor',
        builder: (context, state) => const EditorScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/recent',
        name: 'recent',
        builder: (context, state) => const RecentScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
}
