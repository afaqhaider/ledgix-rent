import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads a local file and returns a URL to reference it by.
abstract class FileStorage {
  Future<String> upload(String remotePath, String localPath);
}

/// Demo mode: just keep the local path.
class LocalFileStorage implements FileStorage {
  @override
  Future<String> upload(String remotePath, String localPath) async => localPath;
}

class FirebaseFileStorage implements FileStorage {
  @override
  Future<String> upload(String remotePath, String localPath) async {
    final ref = FirebaseStorage.instance.ref(remotePath);
    await ref.putFile(File(localPath));
    return ref.getDownloadURL();
  }
}
