import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Uploads a local file and returns a URL to reference it by.
abstract class FileStorage {
  Future<String> upload(String remotePath, String localPath);

  /// Uploads a picked file (camera, gallery or PDF). Web pickers hand over
  /// bytes rather than a path, so this takes the [XFile] itself.
  Future<String> uploadFile(String remotePath, XFile file);
}

/// Largest file a landlord can attach (Storage rules allow 20 MB).
const maxUploadBytes = 20 * 1024 * 1024;

/// Demo mode: just keep the local path.
class LocalFileStorage implements FileStorage {
  @override
  Future<String> upload(String remotePath, String localPath) async => localPath;

  @override
  Future<String> uploadFile(String remotePath, XFile file) async => file.path.isNotEmpty ? file.path : file.name;
}

/// Stores every file under `landlords/{uid}/` so Storage rules can scope
/// access to the signed-in landlord.
class FirebaseFileStorage implements FileStorage {
  FirebaseFileStorage(this.uid, {this.root = 'landlords'});
  final String uid;

  /// `landlords` for landlord files, `tenants` for tenants' own uploads.
  final String root;

  @override
  Future<String> upload(String remotePath, String localPath) async {
    final ref = FirebaseStorage.instance.ref('$root/$uid/$remotePath');
    if (kIsWeb) {
      // In a browser the picker gives a blob: URL, not a file on disk.
      final bytes = await XFile(localPath).readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: _contentType(remotePath)));
    } else {
      await ref.putFile(File(localPath));
    }
    return ref.getDownloadURL();
  }

  @override
  Future<String> uploadFile(String remotePath, XFile file) async {
    if (!kIsWeb && file.path.isNotEmpty) return upload(remotePath, file.path);
    final ref = FirebaseStorage.instance.ref('$root/$uid/$remotePath');
    await ref.putData(await file.readAsBytes(), SettableMetadata(contentType: _contentType(remotePath)));
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
