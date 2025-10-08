import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:teditox/src/core/di/service_locator.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/features/editor/presentation/editor_screen.dart';
import 'package:teditox/src/features/recent/presentation/recent_screen.dart';
import 'package:teditox/src/features/settings/presentation/about_screen.dart';
import 'package:teditox/src/features/settings/presentation/settings_screen.dart';

/// Defines the routes for the application.
enum AppRoute {
  /// The route for the editor screen.
  editor('/', 'editor'),

  /// The route for the settings screen.
  settings('/settings', 'settings', Icons.settings),

  /// The route for the recent files screen.
  recent('/recent', 'recent', Icons.history),

  /// The route for the about screen.
  about('/about', 'about', Icons.info_outline);

  /// Constructor for [AppRoute].
  const AppRoute(this.route, this.name, [this.icon]);

  /// The path of the route.
  final String route;

  /// The name of the route.
  final String name;

  /// The icon associated with the route.
  final IconData? icon;

  /// Returns the localized title for the route.
  String title(AppLocalizations loc) {
    return switch (this) {
      AppRoute.editor => loc.editor,
      AppRoute.settings => loc.settings,
      AppRoute.recent => loc.recent_files,
      AppRoute.about => loc.about,
    };
  }
}

/// Builds the application router with defined routes.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoute.editor.route,
    // Disable deep linking to prevent content:// URIs from being processed as routes
    routes: [
      GoRoute(
        path: AppRoute.editor.route,
        name: AppRoute.editor.name,
        builder: (context, state) {
          sl<Logger>().d('Building editor screen for route: ${state.uri}');
          return const EditorScreen();
        },
      ),
      GoRoute(
        path: AppRoute.settings.route,
        name: AppRoute.settings.name,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoute.recent.route,
        name: AppRoute.recent.name,
        builder: (context, state) => const RecentScreen(),
      ),
      GoRoute(
        path: AppRoute.about.route,
        name: AppRoute.about.name,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
    // Handle invalid routes by showing editor screen
    errorBuilder: (context, state) {
      sl<Logger>().w(
        'Error route detected: ${state.uri}, showing editor screen',
      );
      return const EditorScreen();
    },
  );
}
