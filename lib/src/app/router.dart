import 'package:go_router/go_router.dart';
import 'package:teditox/src/features/editor/presentation/editor_screen.dart';
import 'package:teditox/src/features/recent/presentation/recent_screen.dart';
import 'package:teditox/src/features/settings/presentation/about_screen.dart';
import 'package:teditox/src/features/settings/presentation/settings_screen.dart';

/// Defines the routes for the application.

/// The route for the settings screen.
const settingsRoute = '/settings';

/// The name for the settings route.
const settingsName = 'settings';

/// The route for the recent files screen.
const recentsRoute = '/recent';

/// The name for the recent files route.
const recentsName = 'recent';

/// The route for the about screen.
const aboutRoute = '/about';

/// The name for the about route.
const aboutName = 'about';

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
        name: settingsName,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: recentsRoute,
        name: recentsName,
        builder: (context, state) => const RecentScreen(),
      ),
      GoRoute(
        path: aboutRoute,
        name: aboutName,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
}
