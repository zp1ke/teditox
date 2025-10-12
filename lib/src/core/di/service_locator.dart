import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:teditox/src/core/services/content_uri_service.dart';
import 'package:teditox/src/core/services/encoding_service.dart';
import 'package:teditox/src/core/services/file_service.dart';
import 'package:teditox/src/core/services/intent_service.dart';
import 'package:teditox/src/core/services/preferences_service.dart';
import 'package:teditox/src/core/services/recent_files_service.dart';
import 'package:teditox/src/core/services/recovery_service.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

/// Global service locator instance for dependency injection.
///
/// Provides access to all registered services throughout the application.
final GetIt sl = GetIt.instance;

/// Configures and registers all application dependencies.
///
/// This function should be called during app initialization to set up
/// all services and controllers with their proper dependencies.
Future<void> configureDependencies() async {
  // Preferences
  final prefs = PreferencesService();
  await prefs.init();

  // Settings controller needs prefs to be registered first
  sl.registerSingleton<PreferencesService>(prefs);
  final settings = SettingsController(prefs: sl());
  await settings.load();

  // Register all services with cascades where possible
  sl
    ..registerLazySingleton<Logger>(Logger.new)
    ..registerLazySingleton<EncodingService>(EncodingService.new)
    ..registerLazySingleton<ContentUriService>(
      () => ContentUriService(logger: sl()),
    )
    ..registerLazySingleton<FileService>(
      () => FileService(
        encodingService: sl(),
        contentUriService: sl(),
        logger: sl(),
      ),
    )
    ..registerLazySingleton<RecentFilesService>(
      () => RecentFilesService(prefs: sl()),
    )
    ..registerLazySingleton<RecoveryService>(
      () => RecoveryService(logger: sl()),
    )
    ..registerLazySingleton<IntentService>(
      () => IntentService(logger: sl()),
    )
    ..registerSingleton<SettingsController>(settings)
    ..registerLazySingleton<EditorController>(
      () => EditorController(
        fileService: sl(),
        recentFiles: sl(),
        recoveryService: sl(),
        settings: sl(),
        logger: sl(),
      ),
    );
}
