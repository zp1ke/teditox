import 'package:go_router/go_router.dart';
import 'package:teditox/src/features/editor/presentation/editor_screen.dart';
import 'package:teditox/src/features/recent/presentation/recent_screen.dart';
import 'package:teditox/src/features/settings/presentation/about_screen.dart';
import 'package:teditox/src/features/settings/presentation/settings_screen.dart';

/// Defines the routes for the application.

/// The route for the settings screen.
const settingsRoute = '/settings';

/// The route for the recent files screen.
const recentsRoute = '/recent';

/// The route for the about screen.
const aboutRoute = '/about';

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
        path: settingsRoute,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: recentsRoute,
        name: 'recent',
        builder: (context, state) => const RecentScreen(),
      ),
      GoRoute(
        path: aboutRoute,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
}
