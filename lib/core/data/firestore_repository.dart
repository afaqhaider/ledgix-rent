import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entity.dart';

/// Firestore implementation. Firestore's offline cache gives read access
/// without a connection and syncs when back online.
class FirestoreRepository<T extends Entity> implements CrudRepository<T> {
  FirestoreRepository(this._col, this._fromMap);

  final CollectionReference<Map<String, dynamic>> _col;
  final T Function(Map<String, dynamic>) _fromMap;

  @override
  Stream<List<T>> watchAll() =>
      _col.snapshots().map((s) => [for (final d in s.docs) _fromMap({...d.data(), 'id': d.id})]);

  @override
  Future<T?> get(String id) async {
    final d = await _col.doc(id).get();
    final data = d.data();
    return data == null ? null : _fromMap({...data, 'id': d.id});
  }

  @override
  Future<void> save(T item) => _col.doc(item.id).set(item.toMap());

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
