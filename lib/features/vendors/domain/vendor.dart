import '../../../core/domain/entity.dart';

class Vendor implements Entity {
  const Vendor({required this.id, required this.name, this.trade = '', this.phone = '', this.notes = ''});

  @override
  final String id;
  final String name, trade, phone, notes;

  @override
  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'trade': trade, 'phone': phone, 'notes': notes};

  factory Vendor.fromMap(Map<String, dynamic> m) => Vendor(
        id: m['id'] as String,
        name: '${m['name'] ?? ''}',
        trade: '${m['trade'] ?? ''}',
        phone: '${m['phone'] ?? ''}',
        notes: '${m['notes'] ?? ''}',
      );
}
