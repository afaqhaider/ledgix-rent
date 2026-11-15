import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/utils/file_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CSV bytes start with a UTF-8 BOM and keep Arabic text', () {
    final b = csvBytes('العقار,AED\nبرج,100');
    expect(b.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(b.sublist(3)), 'العقار,AED\nبرج,100');
  });

  test('falls back to the clipboard when sharing is unavailable', () async {
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    // No share plugin in unit tests, so the share sheet throws and we copy.
    final r = await exportCsv('report.csv', 'a,b\n1,2');
    expect(r, ExportResult.copied);
    expect(copied, 'a,b\n1,2');
  });
}
