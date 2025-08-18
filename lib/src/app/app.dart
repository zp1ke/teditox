import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/app/router.dart';
import 'package:teditox/src/core/di/service_locator.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/theme/app_theme.dart';
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
          return AnimatedBuilder(
            animation: settings,
            builder: (context, _) {
              final themeMode = settings.themeMode;
              const schemeSeed = Colors.indigo;
              final themeBuilder = AppTheme(
                lightDynamic: lightDynamic,
                darkDynamic: darkDynamic,
                fallbackSeed: schemeSeed,
                settings: settings,
              );
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context).app_name,
                themeMode: themeMode,
                theme: themeBuilder.buildLightTheme(),
                darkTheme: themeBuilder.buildDarkTheme(),
                routerConfig: buildRouter(),
                locale: settings.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
