/// Base type for everything persisted by a repository.
abstract class Entity {
  String get id;
  Map<String, dynamic> toMap();
}

/// Storage-agnostic repository contract. Firestore today, Postgres later.
abstract class CrudRepository<T extends Entity> {
  Stream<List<T>> watchAll();
  Future<T?> get(String id);
  Future<void> save(T item);
  Future<void> delete(String id);
}

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

DateTime? parseDate(Object? v) => v == null ? null : DateTime.tryParse('$v');

/// A calendar date stored as `yyyy-MM-dd` (no time or time zone), e.g. an ID
/// expiry. Null stays null.
String? dateKey(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
