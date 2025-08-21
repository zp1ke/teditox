import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teditox/src/app/app.dart';
import 'package:teditox/src/core/di/service_locator.dart';
import 'package:teditox/src/core/theme/app_theme.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await configureDependencies();

  for (final font in editorFonts) {
    LicenseRegistry.addLicense(() async* {
      final license = await rootBundle.loadString(
        'fonts/${font.replaceAll(' ', '_')}/OFL.txt',
      );
      yield LicenseEntryWithLineBreaks([font], license);
    });
  }
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const TeditoxApp());
}
