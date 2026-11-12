import '../../../core/domain/entity.dart';

/// A maintenance company (or individual vendor).
class Vendor implements Entity {
  const Vendor({
    required this.id,
    required this.name,
    this.trade = '',
    this.phone = '',
    this.notes = '',
    this.tradeLicenceNo = '',
    this.contactPerson = '',
    this.email = '',
    this.services = const [],
    this.areasCovered = const [],
    this.linkedAccountId,
    this.defaultCategories = const [],
  });

  @override
  final String id;
  final String name, trade, phone, notes, tradeLicenceNo, contactPerson, email;
  final List<String> services, areasCovered;

  /// LedGix Rent account of the company, if it uses the app (work orders go in-app).
  final String? linkedAccountId;

  /// Categories this company is the default for (TicketCategory names).
  final List<String> defaultCategories;

  bool get usesApp => linkedAccountId != null && linkedAccountId!.isNotEmpty;

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'trade': trade,
        'phone': phone,
        'notes': notes,
        'tradeLicenceNo': tradeLicenceNo,
        'contactPerson': contactPerson,
        'email': email,
        'services': services,
        'areasCovered': areasCovered,
        'linkedAccountId': linkedAccountId,
        'defaultCategories': defaultCategories,
      };

  static List<String> _list(Object? v) => [for (final e in (v as List? ?? const [])) '$e'];

  factory Vendor.fromMap(Map<String, dynamic> m) => Vendor(
        id: m['id'] as String,
        name: '${m['name'] ?? ''}',
        trade: '${m['trade'] ?? ''}',
        phone: '${m['phone'] ?? ''}',
        notes: '${m['notes'] ?? ''}',
        tradeLicenceNo: '${m['tradeLicenceNo'] ?? ''}',
        contactPerson: '${m['contactPerson'] ?? ''}',
        email: '${m['email'] ?? ''}',
        services: _list(m['services']),
        areasCovered: _list(m['areasCovered']),
        linkedAccountId: m['linkedAccountId'] as String?,
        defaultCategories: _list(m['defaultCategories']),
      );
}
