import 'dart:typed_data';

/// Not a browser: files go through the share sheet instead.
const canDownload = false;

void download(String filename, Uint8List bytes, String mimeType) => throw UnsupportedError('download');
