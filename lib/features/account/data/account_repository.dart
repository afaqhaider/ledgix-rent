import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';

/// Reads and writes `users/{uid}`.
abstract class AccountRepository {
  Stream<AppUser?> watch(String uid);
  Future<void> save(AppUser user);
}

class FirestoreAccountRepository implements AccountRepository {
  final _col = FirebaseFirestore.instance.collection('users');

  @override
  Stream<AppUser?> watch(String uid) => _col.doc(uid).snapshots().map((s) {
        final d = s.data();
        // A users doc that only holds push tokens (older builds) has no role yet.
        if (d == null || d['role'] == null) return null;
        return AppUser.fromMap({...d, 'id': uid});
      });

  /// Merges, so push tokens written by PushService are kept.
  @override
  Future<void> save(AppUser user) =>
      _col.doc(user.id).set({...user.toMap(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}

/// Demo mode and tests: accounts live for the app session.
class InMemoryAccountRepository implements AccountRepository {
  static final _users = <String, AppUser>{};
  static final _changes = StreamController<void>.broadcast();

  /// Clears all demo accounts (tests).
  static void reset() => _users.clear();

  /// Demo lookups for the connections feature.
  static AppUser? byId(String uid) => _users[uid];
  static AppUser? byEmail(String email) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return null;
    return _users.values.where((u) => u.email.trim().toLowerCase() == e).firstOrNull;
  }

  @override
  Stream<AppUser?> watch(String uid) async* {
    yield _users[uid];
    yield* _changes.stream.map((_) => _users[uid]);
  }

  @override
  Future<void> save(AppUser user) async {
    _users[user.id] = user;
    _changes.add(null);
  }
}
