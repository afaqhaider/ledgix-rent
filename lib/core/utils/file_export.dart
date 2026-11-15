import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import 'file_export_stub.dart' if (dart.library.js_interop) 'file_export_web.dart' as platform;

/// How an exported file reached the user.
enum ExportResult { downloaded, shared, copied }

/// CSV bytes with a UTF-8 byte-order mark so Excel opens Arabic text correctly.
Uint8List csvBytes(String csv) => Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

/// Saves [csv] as [filename]: a real download in the browser, the system share
/// sheet with a .csv file on phones, and the clipboard if neither works.
/// [anchor] positions the share popover on iPad.
Future<ExportResult> exportCsv(String filename, String csv, {BuildContext? anchor}) async {
  final bytes = csvBytes(csv);
  try {
    if (platform.canDownload) {
      platform.download(filename, bytes, 'text/csv');
      return ExportResult.downloaded;
    }
    Rect? origin;
    final box = anchor?.findRenderObject();
    if (box is RenderBox && box.hasSize) origin = box.localToGlobal(Offset.zero) & box.size;
    final r = await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'text/csv', name: filename)],
      fileNameOverrides: [filename],
      sharePositionOrigin: origin,
    ));
    if (r.status == ShareResultStatus.unavailable) throw StateError('share unavailable');
    return ExportResult.shared;
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: csv));
    return ExportResult.copied;
  }
}
