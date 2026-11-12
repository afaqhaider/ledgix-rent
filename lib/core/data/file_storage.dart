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

/// Stores every file under `landlords/{uid}/` so Storage rules can scope
/// access to the signed-in landlord.
class FirebaseFileStorage implements FileStorage {
  FirebaseFileStorage(this.uid);
  final String uid;

  @override
  Future<String> upload(String remotePath, String localPath) async {
    final ref = FirebaseStorage.instance.ref('landlords/$uid/$remotePath');
    await ref.putFile(File(localPath));
    return ref.getDownloadURL();
  }
}
