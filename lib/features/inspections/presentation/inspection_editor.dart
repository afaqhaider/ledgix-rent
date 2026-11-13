import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';

import '../../../core/domain/entity.dart';
import '../data/inspection_media.dart';
import '../domain/inspection.dart';

/// Where a photo or video belongs.
sealed class MediaTarget {
  const MediaTarget();
}

class RoomMedia extends MediaTarget {
  const RoomMedia(this.roomId);
  final String roomId;
}

class ItemMedia extends MediaTarget {
  const ItemMedia(this.roomId, this.itemId);
  final String roomId, itemId;
}

class MeterMedia extends MediaTarget {
  const MeterMedia();
}

Inspection addMediaTo(Inspection i, MediaTarget t, InspectionMedia m) => switch (t) {
      RoomMedia(:final roomId) => i.copyWith(rooms: [
          for (final r in i.rooms) r.id == roomId ? r.copyWith(media: [...r.media, m]) : r,
        ]),
      ItemMedia(:final roomId, :final itemId) => i.copyWith(rooms: [
          for (final r in i.rooms)
            r.id == roomId
                ? r.copyWith(items: [for (final it in r.items) it.id == itemId ? it.copyWith(media: [...it.media, m]) : it])
                : r,
        ]),
      MeterMedia() => i.copyWith(meters: i.meters.copyWith(photos: [...i.meters.photos, m])),
    };

Inspection removeMediaFrom(Inspection i, MediaTarget t, InspectionMedia m) {
  List<InspectionMedia> drop(List<InspectionMedia> l) => [for (final x in l) if (x.url != m.url) x];
  return switch (t) {
    RoomMedia(:final roomId) => i.copyWith(rooms: [
        for (final r in i.rooms) r.id == roomId ? r.copyWith(media: drop(r.media)) : r,
      ]),
    ItemMedia(:final roomId, :final itemId) => i.copyWith(rooms: [
        for (final r in i.rooms)
          r.id == roomId
              ? r.copyWith(items: [for (final it in r.items) it.id == itemId ? it.copyWith(media: drop(it.media)) : it])
              : r,
      ]),
    MeterMedia() => i.copyWith(meters: i.meters.copyWith(photos: drop(i.meters.photos))),
  };
}

class PendingUpload {
  PendingUpload(this.target, this.type);
  final MediaTarget target;
  final MediaType type;
  double progress = 0;
}

/// Holds a draft inspection while the landlord walks through the unit.
/// Every change shows immediately and is saved half a second later; uploads
/// run in the background so typing and rating never wait for the network.
/// An upload that finishes after the screen is closed still lands in the
/// saved inspection.
class InspectionEditor extends ChangeNotifier {
  InspectionEditor({required Inspection initial, required this.repo, required this.media, DateTime Function()? clock})
      : _value = initial,
        _now = clock ?? DateTime.now;

  final CrudRepository<Inspection> repo;
  final InspectionMediaStore media;
  final DateTime Function() _now;

  Inspection _value;
  Inspection get value => _value;

  Timer? _saveTimer;
  bool _disposed = false;
  final List<PendingUpload> pending = [];

  /// Last upload error, shown once by the screen.
  Object? lastError;

  void update(Inspection Function(Inspection) f) {
    _value = f(_value);
    _scheduleSave();
    notifyListeners();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), flush);
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    await repo.save(_value);
  }

  /// Uploads [file] in the background and attaches it to [target].
  Future<void> addMedia(MediaTarget target, XFile file, MediaType type) async {
    final p = PendingUpload(target, type);
    pending.add(p);
    _notify();
    try {
      final up = await media.upload(_value.id, file, type: type, onProgress: (v) {
        p.progress = v;
        _notify();
      });
      final m = InspectionMedia(url: up.url, storagePath: up.storagePath, type: type, takenAt: _now(), by: MediaBy.landlord);
      if (_disposed) {
        // Screen closed: write straight to the saved copy.
        final saved = await repo.get(_value.id);
        if (saved != null) await repo.save(addMediaTo(saved, target, m));
      } else {
        update((i) => addMediaTo(i, target, m));
      }
    } catch (e) {
      lastError = e;
    } finally {
      pending.remove(p);
      _notify();
    }
  }

  void removeMedia(MediaTarget target, InspectionMedia m) => update((i) => removeMediaFrom(i, target, m));

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_saveTimer != null) unawaited(flush());
    _disposed = true;
    super.dispose();
  }
}
