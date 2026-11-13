import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../domain/inspection.dart';

/// Largest inspection photo (Storage rules: 20 MB) and video (200 MB).
const maxInspectionPhotoBytes = 20 * 1024 * 1024;
const maxInspectionVideoBytes = 200 * 1024 * 1024;

/// Longest video the picker records.
const maxInspectionVideo = Duration(minutes: 2);

/// Photos are scaled down to this width/height before upload.
const inspectionPhotoMaxSide = 1600.0;

class UploadedMedia {
  const UploadedMedia(this.url, this.storagePath);
  final String url, storagePath;
}

class MediaTooLarge implements Exception {
  const MediaTooLarge(this.bytes, this.limit);
  final int bytes, limit;
  @override
  String toString() => 'File is ${(bytes / 1048576).toStringAsFixed(1)} MB; the limit is ${limit ~/ 1048576} MB.';
}

/// Uploads inspection photos and videos with progress.
abstract class InspectionMediaStore {
  Future<UploadedMedia> upload(
    String inspectionId,
    XFile file, {
    required MediaType type,
    void Function(double progress)? onProgress,
  });
}

String _ext(XFile f) {
  final n = f.name.isNotEmpty ? f.name : f.path;
  final dot = n.lastIndexOf('.');
  return dot < 0 ? '' : n.substring(dot + 1).toLowerCase();
}

String? mediaContentType(String ext, MediaType type) => switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'm4v' => 'video/x-m4v',
      'webm' => 'video/webm',
      _ => type == MediaType.video ? 'video/mp4' : 'image/jpeg',
    };

Future<void> checkMediaSize(XFile file, MediaType type) async {
  final size = await file.length();
  final limit = type == MediaType.video ? maxInspectionVideoBytes : maxInspectionPhotoBytes;
  if (size > limit) throw MediaTooLarge(size, limit);
}

/// Demo mode and tests: keeps the local path (or blob URL on the web).
class LocalInspectionMediaStore implements InspectionMediaStore {
  @override
  Future<UploadedMedia> upload(String inspectionId, XFile file,
      {required MediaType type, void Function(double progress)? onProgress}) async {
    onProgress?.call(1);
    final p = file.path.isNotEmpty ? file.path : file.name;
    return UploadedMedia(p, p);
  }
}

/// Landlord uploads go to `landlords/{uid}/inspections/{id}/`, tenant
/// uploads to `tenantUploads/{uid}/inspections/{id}/` (see storage.rules).
class FirebaseInspectionMediaStore implements InspectionMediaStore {
  FirebaseInspectionMediaStore(this.uid, {this.asTenant = false});
  final String uid;
  final bool asTenant;

  String folder(String inspectionId) =>
      asTenant ? 'tenantUploads/$uid/inspections/$inspectionId' : 'landlords/$uid/inspections/$inspectionId';

  @override
  Future<UploadedMedia> upload(String inspectionId, XFile file,
      {required MediaType type, void Function(double progress)? onProgress}) async {
    await checkMediaSize(file, type);
    final ext = _ext(file);
    final name = '${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '' : '.$ext'}';
    final path = '${folder(inspectionId)}/$name';
    final ref = FirebaseStorage.instance.ref(path);
    final meta = SettableMetadata(contentType: mediaContentType(ext, type));
    final UploadTask task = (!kIsWeb && file.path.isNotEmpty)
        ? ref.putFile(File(file.path), meta)
        : ref.putData(await file.readAsBytes(), meta);
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });
    try {
      await task;
    } finally {
      await sub.cancel();
    }
    return UploadedMedia(await ref.getDownloadURL(), path);
  }
}
