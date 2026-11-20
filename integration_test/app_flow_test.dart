import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teditox/main.dart' as app;

/// Boots the real app once (configureDependencies registers GetIt singletons,
/// which must not run twice in one process).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches on the editor and typing marks the buffer dirty', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();

    // App bar shows the localized app name.
    expect(find.textContaining('TeditoX'), findsWidgets);

    final editor = find.byType(TextField);
    expect(editor, findsWidgets);

    // Typing into the editor should raise the unsaved-changes marker.
    await tester.enterText(editor.first, 'hello from integration test');
    await tester.pumpAndSettle();

    expect(find.text('hello from integration test'), findsWidgets);
    expect(find.textContaining('TeditoX *'), findsWidgets);
  });
}
