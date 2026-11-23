import 'package:flutter_test/flutter_test.dart';
import 'package:teditox/src/core/services/intent_service.dart';

void main() {
  test(
    'a content URI from a file manager is opened even without an extension',
    () {
      expect(
        shouldOpenIncoming(
          'content://com.android.providers.downloads.documents/document/2147',
          'text/plain',
        ),
        isTrue,
      );
      expect(
        shouldOpenIncoming(
          'content://com.android.providers.downloads.documents/document/2147',
          null,
        ),
        isTrue,
      );
      expect(
        shouldOpenIncoming('content://media/external/images/1', 'image/jpeg'),
        isFalse,
      );
    },
  );
}
