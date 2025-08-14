import 'package:flutter/material.dart';

/// A reusable primary button widget with consistent styling.
///
/// This widget provides a standardized primary button appearance using
/// Flutter's FilledButton with the app's theme styling.
class PrimaryButton extends StatelessWidget {
  /// Creates a primary button widget.
  ///
  /// The [label] and [onPressed] parameters are required.
  /// If [onPressed] is null, the button will be disabled.
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// The text to display on the button.
  final String label;

  /// The callback function called when the button is pressed.
  ///
  /// If null, the button will be disabled and cannot be pressed.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
