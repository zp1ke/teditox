import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/app/router.dart';
import 'package:teditox/src/core/di/service_locator.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/services/intent_service.dart';
import 'package:teditox/src/core/theme/app_theme.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

/// The main application widget for Teditox.
class TeditoxApp extends StatelessWidget {
  /// Creates a Teditox application widget.
  const TeditoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsController>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
      ],
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return _AppContent(
            lightDynamic: lightDynamic,
            darkDynamic: darkDynamic,
          );
        },
      ),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent({
    required this.lightDynamic,
    required this.darkDynamic,
  });

  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  late final GoRouter _router;
  late ThemeMode _themeMode;
  late Locale? _locale;
  late String? _fontFamily;
  late SettingsController _settings;
  late IntentService _intentService;
  late Logger _logger;

  @override
  void initState() {
    super.initState();
    _logger = sl<Logger>();
    _router = buildRouter();
    _settings = context.read<SettingsController>();
    _themeMode = _settings.themeMode;
    _locale = _settings.locale;
    _fontFamily = _settings.currentFontFamily;
    _settings.addListener(_onSettingsChanged);

    // Initialize intent service to handle incoming file intents
    _intentService = sl<IntentService>();
    _intentService.initialize(
      onFileReceived: _handleIncomingFile,
    );

    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _intentService.dispose();
    _router.dispose();
    super.dispose();
  }

  void _handleIncomingFile(String filePath) {
    _logger.i('Received file intent: $filePath');

    // Schedule the file opening after the first frame is rendered
    // This ensures the widget tree is fully built and router is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.d('PostFrameCallback triggered, opening file');
      _openFileWhenReady(filePath);
    });
  }

  /// Gets a valid context for navigation operations.
  BuildContext? get _navigatorContext {
    if (mounted) return context;
    return _router.routerDelegate.navigatorKey.currentContext;
  }

  /// Opens the file once the router and context are ready.
  void _openFileWhenReady(String filePath) {
    final navContext = _navigatorContext;

    if (navContext != null && navContext.mounted) {
      _logger.d('Opening file: $filePath');
      final editorController = sl<EditorController>();

      // Skip confirmation when opening from external intent at startup
      unawaited(
        editorController.openFileByPath(
          navContext,
          filePath,
          skipConfirmation: true,
        ),
      );
    } else {
      _logger.w('Context not ready yet, retrying...');
      // If context is not ready, wait for next frame and try again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openFileWhenReady(filePath);
      });
    }
  }

  void _onSettingsChanged() {
    // Only rebuild if app-level settings changed
    final newThemeMode = _settings.themeMode;
    final newLocale = _settings.locale;
    final newFont = _settings.currentFontFamily;

    if (newThemeMode != _themeMode ||
        newLocale != _locale ||
        newFont != _fontFamily) {
      setState(() {
        _themeMode = newThemeMode;
        _locale = newLocale;
        _fontFamily = newFont;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBuilder = AppTheme(
      lightDynamic: widget.lightDynamic,
      darkDynamic: widget.darkDynamic,
      fallbackSeed: Colors.indigo,
      settings: _settings,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).app_name,
      themeMode: _themeMode,
      theme: themeBuilder.buildLightTheme(),
      darkTheme: themeBuilder.buildDarkTheme(),
      routerConfig: _router,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
