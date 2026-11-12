import '../../../core/domain/entity.dart';

enum TicketPriority { low, medium, high, urgent }

enum TicketStatus { open, inProgress, resolved }

class MaintenanceTicket implements Entity {
  const MaintenanceTicket({
    required this.id,
    required this.propertyId,
    required this.title,
    this.raisedBy = 'landlord',
    this.description = '',
    this.photos = const [],
    this.priority = TicketPriority.medium,
    this.status = TicketStatus.open,
    this.vendorId,
    this.cost = 0,
  });

  @override
  final String id;
  final String propertyId, title, raisedBy, description;
  final List<String> photos;
  final TicketPriority priority;
  final TicketStatus status;
  final String? vendorId;
  final double cost;

  MaintenanceTicket copyWith({TicketStatus? status, String? vendorId, double? cost}) =>
      MaintenanceTicket(
        id: id,
        propertyId: propertyId,
        title: title,
        raisedBy: raisedBy,
        description: description,
        photos: photos,
        priority: priority,
        status: status ?? this.status,
        vendorId: vendorId ?? this.vendorId,
        cost: cost ?? this.cost,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'raisedBy': raisedBy,
        'title': title,
        'description': description,
        'photos': photos,
        'priority': priority.name,
        'status': status.name,
        'vendorId': vendorId,
        'cost': cost,
      };

  factory MaintenanceTicket.fromMap(Map<String, dynamic> m) => MaintenanceTicket(
        id: m['id'] as String,
        propertyId: '${m['propertyId']}',
        raisedBy: '${m['raisedBy'] ?? 'landlord'}',
        title: '${m['title'] ?? ''}',
        description: '${m['description'] ?? ''}',
        photos: [for (final p in (m['photos'] as List? ?? const [])) '$p'],
        priority: enumByName(TicketPriority.values, m['priority'], TicketPriority.medium),
        status: enumByName(TicketStatus.values, m['status'], TicketStatus.open),
        vendorId: m['vendorId'] as String?,
        cost: ((m['cost'] ?? 0) as num).toDouble(),
      );
}
