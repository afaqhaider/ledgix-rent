import 'dart:async';

import '../domain/entity.dart';

/// Used for demo mode and tests (no Firebase needed).
class InMemoryRepository<T extends Entity> implements CrudRepository<T> {
  final Map<String, T> _items = {};
  final _controller = StreamController<List<T>>.broadcast();

  /// Fires after any demo repository changes (the demo tenant view listens).
  static final changes = StreamController<void>.broadcast();

  List<T> get _list => _items.values.toList();

  /// Current items, synchronously (demo projections).
  List<T> get items => _list;

  @override
  Stream<List<T>> watchAll() async* {
    yield _list;
    yield* _controller.stream;
  }

  @override
  Future<T?> get(String id) async => _items[id];

  @override
  Future<void> save(T item) async {
    _items[item.id] = item;
    _controller.add(_list);
    changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _controller.add(_list);
    changes.add(null);
  }
}
