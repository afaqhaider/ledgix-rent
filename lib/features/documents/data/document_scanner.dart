import 'dart:io';
import 'dart:math' as math;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

import '../domain/document_reader.dart';
import '../domain/scanned_document.dart';
import '../domain/text_layout.dart';

/// Reads a photo or PDF of a document on the device and recognises it.
abstract class DocumentScanner {
  /// On-device OCR runs on iOS and Android only.
  bool get isSupported;
  Future<ScannedDocument> scan(XFile file);
}

/// On-device text recognition through the app's "ledgix/ocr" channel: Apple
/// Vision on iOS, Google ML Kit (Latin) on Android. Nothing leaves the phone.
/// PDFs are rendered page by page (first [maxPages]) and read like photos.
class DeviceDocumentScanner implements DocumentScanner {
  static const _channel = MethodChannel('ledgix/ocr');

  static const maxPages = 3;

  @override
  bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<ScannedDocument> scan(XFile file) async => const DocumentReader().read(await readRows(file));

  /// Printed rows of text, in reading order, across all pages.
  Future<List<String>> readRows(XFile file) async {
    final temp = <File>[];
    try {
      final images = <String>[];
      if (_isPdf(file)) {
        final doc = await PdfDocument.openFile(file.path);
        try {
          for (var i = 1; i <= math.min(doc.pagesCount, maxPages); i++) {
            final page = await doc.getPage(i);
            try {
              // ~200 dpi: small print on Ejari forms needs the extra pixels.
              final img = await page.render(width: page.width * 2.8, height: page.height * 2.8, format: PdfPageImageFormat.png, backgroundColor: '#FFFFFF');
              if (img == null) continue;
              final out = File('${Directory.systemTemp.path}/ledgix_scan_${DateTime.now().microsecondsSinceEpoch}_$i.png');
              await out.writeAsBytes(img.bytes);
              temp.add(out);
              images.add(out.path);
            } finally {
              await page.close();
            }
          }
        } finally {
          await doc.close();
        }
      } else {
        images.add(file.path);
      }
      final rows = <String>[];
      for (final path in images) {
        final lines = await _channel.invokeListMethod<Map<Object?, Object?>>('recognize', {'path': path}) ?? const [];
        rows.addAll(rowsFromLines([
          for (final m in lines)
            OcrLine('${m['text']}', (m['left'] as num).toDouble(), (m['top'] as num).toDouble(), (m['right'] as num).toDouble(),
                (m['bottom'] as num).toDouble()),
        ]));
      }
      return rows;
    } finally {
      for (final f in temp) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  }

  static bool _isPdf(XFile f) => f.name.toLowerCase().endsWith('.pdf') || f.path.toLowerCase().endsWith('.pdf') || f.mimeType == 'application/pdf';
}
