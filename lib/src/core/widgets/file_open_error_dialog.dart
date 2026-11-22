import 'package:material_ui/material_ui.dart';
import 'package:teditox/src/app/router.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/services/file_service.dart';
import 'package:teditox/src/core/utils/byte_size_formatter.dart';
import 'package:teditox/src/core/utils/context.dart';

/// Explains why a file could not be opened.
///
/// Offers Settings when the file is over the size limit.
Future<void> showFileOpenError(BuildContext context, FileOpenException error) {
  final loc = AppLocalizations.of(context);
  final name = error.path == null
      ? loc.file_unreadable_unknown
      : (displayNameForPath(error.path!) ?? loc.shared_document);
  final message = switch (error.failure) {
    FileOpenFailure.tooLarge => loc.file_too_large(
      formatBytes(error.limitBytes ?? 0),
    ),
    FileOpenFailure.notFound => loc.file_not_found(name),
    FileOpenFailure.unreadable => loc.file_unreadable(name),
  };
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      semanticLabel: loc.open_file_error,
      title: Text(loc.open_file_error),
      content: Text(message),
      actions: [
        if (error.failure == FileOpenFailure.tooLarge)
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.navigate(AppRoute.settings);
            },
            child: Text(loc.settings),
          ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(loc.ok),
        ),
      ],
    ),
  );
}
