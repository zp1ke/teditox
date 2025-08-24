import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Extension for [BuildContext] to add navigation utilities.
extension ContextX on BuildContext {
  /// Navigate back in the app's navigation stack.
  void navigateBack() {
    if (Navigator.canPop(this)) {
      Navigator.pop(this);
    } else {
      go('/');
    }
  }
}
