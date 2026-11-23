import 'package:flutter_test/flutter_test.dart';
import 'package:teditox/src/core/services/content_uri_service.dart';

void main() {
  test('ENOENT from a content URI is a missing document', () {
    const message = 'open failed: ENOENT (No such file or directory)';
    expect(contentUriIsMissing(message), isTrue);
    expect(contentUriIsMissing('Permission denied'), isFalse);
  });
}
