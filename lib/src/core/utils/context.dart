import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:teditox/src/app/router.dart';

/// Extension for [BuildContext] to add navigation utilities.
extension ContextX on BuildContext {
  /// Navigate back in the app's navigation stack.
  void navigateBack() {
    if (canPop()) {
      return pop(this);
    }
    navigate(AppRoute.editor, cleanStack: true);
  }

  /// Navigate to a specific [AppRoute].
  /// If [cleanStack] is true, it replaces the current stack.
  /// Otherwise, it pushes the new route onto the stack.
  void navigate(AppRoute route, {bool cleanStack = false}) {
    if (cleanStack) {
      return go(route.route);
    }
    unawaited(push(route.route));
  }
}
