import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';

/// Result of the unsaved changes dialog.
enum UnsavedChangesAction {
  /// User chose to cancel the operation.
  cancel,

  /// User chose to save the changes.
  save,

  /// User chose to discard the changes.
  discard,
}

/// A reusable dialog that asks the user what to do with unsaved changes.
///
/// Returns [UnsavedChangesAction] indicating the user's choice, or null if
/// the dialog was dismissed.
class UnsavedChangesDialog extends StatelessWidget {
  /// Creates an unsaved changes dialog.
  const UnsavedChangesDialog({super.key});

  /// Shows the unsaved changes dialog and returns the user's choice.
  ///
  /// Returns [UnsavedChangesAction.cancel] if the user cancels,
  /// [UnsavedChangesAction.save] if they want to save,
  /// [UnsavedChangesAction.discard] if they want to discard changes,
  /// or null if the dialog was dismissed.
  static Future<UnsavedChangesAction?> show(BuildContext context) {
    return showDialog<UnsavedChangesAction>(
      context: context,
      builder: (context) => const UnsavedChangesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(loc.unsaved_changes),
      content: Text(loc.unsaved_changes_message),
      actions: [
        TextButton(
          onPressed: () => context.pop(UnsavedChangesAction.cancel),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () => context.pop(UnsavedChangesAction.save),
          child: Text(loc.save),
        ),
        TextButton(
          onPressed: () => context.pop(UnsavedChangesAction.discard),
          child: Text(loc.discard),
        ),
      ],
    );
  }
}
