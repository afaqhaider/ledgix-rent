import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Uploads a local file and returns a URL to reference it by.
abstract class FileStorage {
  Future<String> upload(String remotePath, String localPath);
}

/// Demo mode: just keep the local path.
class LocalFileStorage implements FileStorage {
  @override
  Future<String> upload(String remotePath, String localPath) async => localPath;
}

/// Stores every file under `landlords/{uid}/` so Storage rules can scope
/// access to the signed-in landlord.
class FirebaseFileStorage implements FileStorage {
  FirebaseFileStorage(this.uid);
  final String uid;

  @override
  Future<String> upload(String remotePath, String localPath) async {
    final ref = FirebaseStorage.instance.ref('landlords/$uid/$remotePath');
    if (kIsWeb) {
      // In a browser the picker gives a blob: URL, not a file on disk.
      final bytes = await XFile(localPath).readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: _contentType(remotePath)));
    } else {
      await ref.putFile(File(localPath));
    }
    return ref.getDownloadURL();
  }

  static String? _contentType(String name) => switch (name.split('.').last.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        'pdf' => 'application/pdf',
        _ => null,
      };
}
