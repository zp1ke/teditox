import 'package:flutter_test/flutter_test.dart';
import 'package:teditox/src/features/editor/presentation/editor_layout.dart';

void main() {
  test('wide and tall tablets use the side panel, phones use a drawer', () {
    expect(editorShowsSidePanel(width: 1280, enabled: true), isTrue);
    expect(editorShowsSidePanel(width: 800, enabled: true), isTrue);
    expect(editorShowsSidePanel(width: 1280, enabled: false), isFalse);
    expect(editorUsesDrawer(400), isTrue);
    expect(editorUsesDrawer(800), isFalse);
  });
}
