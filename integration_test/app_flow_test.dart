import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:teditox/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Startup and shows app title', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    expect(find.textContaining('teditox'), findsWidgets);
  });
}
