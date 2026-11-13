import 'inspection.dart';

/// One item compared between the move-in and the move-out walkthrough.
class ItemComparison {
  const ItemComparison({required this.roomName, required this.itemName, this.moveIn, this.moveOut});
  final String roomName, itemName;
  final InspectionItem? moveIn, moveOut;

  /// True when both were rated and the move-out condition is worse
  /// (e.g. good -> damaged). "Not applicable" never counts.
  bool get worsened {
    final a = moveIn?.condition?.rank, b = moveOut?.condition?.rank;
    return a != null && b != null && b > a;
  }

  /// Present at move-in but removed from the move-out list.
  bool get missingAtMoveOut => moveIn != null && moveOut == null;

  /// How many steps worse (0 when not worse).
  int get severity {
    final a = moveIn?.condition?.rank, b = moveOut?.condition?.rank;
    return (a != null && b != null && b > a) ? b - a : 0;
  }
}

/// Copies a completed move-in's rooms and items (names only: conditions,
/// notes and media start empty) as the starting point for a move-out, keeping
/// the same room and item ids so the two can be matched.
List<InspectionRoom> moveOutRoomsFrom(Inspection moveIn) => [
      for (final r in moveIn.rooms)
        InspectionRoom(id: r.id, name: r.name, items: [for (final i in r.items) InspectionItem(id: i.id, name: i.name)]),
    ];

/// Pairs every item of [moveOut] with its move-in counterpart, matching by
/// room+item id first and falling back to room+item name (case-insensitive),
/// so items keep matching after a rename or when the move-in was entered
/// separately. Move-in items with no counterpart are listed too.
List<ItemComparison> compareInspections(Inspection moveIn, Inspection moveOut) {
  String key(String room, String item) => '${room.trim().toLowerCase()}|${item.trim().toLowerCase()}';
  final byId = <String, (InspectionRoom, InspectionItem)>{};
  final byName = <String, (InspectionRoom, InspectionItem)>{};
  for (final r in moveIn.rooms) {
    for (final i in r.items) {
      byId['${r.id}|${i.id}'] = (r, i);
      byName[key(r.name, i.name)] = (r, i);
    }
  }
  final used = <InspectionItem>{};
  final out = <ItemComparison>[];
  for (final r in moveOut.rooms) {
    for (final i in r.items) {
      final match = byId['${r.id}|${i.id}'] ?? byName[key(r.name, i.name)];
      if (match != null) used.add(match.$2);
      out.add(ItemComparison(roomName: r.name, itemName: i.name, moveIn: match?.$2, moveOut: i));
    }
  }
  for (final r in moveIn.rooms) {
    for (final i in r.items) {
      if (!used.contains(i)) out.add(ItemComparison(roomName: r.name, itemName: i.name, moveIn: i));
    }
  }
  return out;
}

/// Items that got worse, most severe first — the basis for deposit deductions.
List<ItemComparison> worsenedItems(Inspection moveIn, Inspection moveOut) {
  final w = compareInspections(moveIn, moveOut).where((c) => c.worsened).toList();
  w.sort((a, b) => b.severity.compareTo(a.severity));
  return w;
}
