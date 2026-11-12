import '../../../core/domain/entity.dart';

enum TicketPriority { low, medium, high, urgent }

/// Maintenance job lifecycle. `open` = logged, not yet sent to a company.
enum TicketStatus { open, requested, quoted, approved, scheduled, inProgress, completed, closed }

enum TicketCategory { ac, plumbing, electrical, appliances, pestControl, painting, other }

enum ForwardChannel { app, email }

class MaintenanceTicket implements Entity {
  const MaintenanceTicket({
    required this.id,
    required this.propertyId,
    required this.title,
    this.raisedBy = 'landlord',
    this.description = '',
    this.photos = const [],
    this.videos = const [],
    this.priority = TicketPriority.medium,
    this.status = TicketStatus.open,
    this.vendorId,
    this.cost = 0,
    this.category = TicketCategory.other,
    this.visitRequired = false,
    this.timeSlots = const [],
    this.accessNotes = '',
    this.landlordNote = '',
    this.forwardedToVendorId,
    this.forwardChannel,
    this.shareTenantContact = false,
    this.tenantRating,
    this.confirmedVisit,
  });

  @override
  final String id;
  final String propertyId, title, raisedBy, description, accessNotes, landlordNote;
  final List<String> photos, videos;
  final TicketPriority priority;
  final TicketStatus status;
  final String? vendorId, forwardedToVendorId;
  final double cost;
  final TicketCategory category;
  final bool visitRequired, shareTenantContact;

  /// Up to 3 time slots the tenant is available for a visit.
  final List<DateTime> timeSlots;
  final ForwardChannel? forwardChannel;
  final int? tenantRating;
  final DateTime? confirmedVisit;

  bool get isClosedOut => status == TicketStatus.completed || status == TicketStatus.closed;

  MaintenanceTicket copyWith({
    TicketStatus? status,
    String? vendorId,
    double? cost,
    String? landlordNote,
    String? forwardedToVendorId,
    ForwardChannel? forwardChannel,
    bool? shareTenantContact,
    int? tenantRating,
    DateTime? confirmedVisit,
    List<String>? photos,
  }) =>
      MaintenanceTicket(
        id: id,
        propertyId: propertyId,
        title: title,
        raisedBy: raisedBy,
        description: description,
        photos: photos ?? this.photos,
        videos: videos,
        priority: priority,
        status: status ?? this.status,
        vendorId: vendorId ?? this.vendorId,
        cost: cost ?? this.cost,
        category: category,
        visitRequired: visitRequired,
        timeSlots: timeSlots,
        accessNotes: accessNotes,
        landlordNote: landlordNote ?? this.landlordNote,
        forwardedToVendorId: forwardedToVendorId ?? this.forwardedToVendorId,
        forwardChannel: forwardChannel ?? this.forwardChannel,
        shareTenantContact: shareTenantContact ?? this.shareTenantContact,
        tenantRating: tenantRating ?? this.tenantRating,
        confirmedVisit: confirmedVisit ?? this.confirmedVisit,
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'propertyId': propertyId,
        'raisedBy': raisedBy,
        'title': title,
        'description': description,
        'photos': photos,
        'videos': videos,
        'priority': priority.name,
        'status': status.name,
        'vendorId': vendorId,
        'cost': cost,
        'category': category.name,
        'urgency': priority.name,
        'visitRequired': visitRequired,
        'timeSlots': [for (final t in timeSlots) t.toIso8601String()],
        'accessNotes': accessNotes,
        'landlordNote': landlordNote,
        'forwardedToVendorId': forwardedToVendorId,
        'forwardChannel': forwardChannel?.name,
        'shareTenantContact': shareTenantContact,
        'tenantRating': tenantRating,
        'confirmedVisit': confirmedVisit?.toIso8601String(),
      };

  factory MaintenanceTicket.fromMap(Map<String, dynamic> m) => MaintenanceTicket(
        id: m['id'] as String,
        propertyId: '${m['propertyId']}',
        raisedBy: '${m['raisedBy'] ?? 'landlord'}',
        title: '${m['title'] ?? ''}',
        description: '${m['description'] ?? ''}',
        photos: [for (final p in (m['photos'] as List? ?? const [])) '$p'],
        videos: [for (final p in (m['videos'] as List? ?? const [])) '$p'],
        priority: enumByName(TicketPriority.values, m['priority'], TicketPriority.medium),
        status: enumByName(TicketStatus.values, m['status'], TicketStatus.open),
        vendorId: m['vendorId'] as String?,
        cost: ((m['cost'] ?? 0) as num).toDouble(),
        category: enumByName(TicketCategory.values, m['category'], TicketCategory.other),
        visitRequired: m['visitRequired'] == true,
        timeSlots: [for (final t in (m['timeSlots'] as List? ?? const [])) DateTime.parse('$t')],
        accessNotes: '${m['accessNotes'] ?? ''}',
        landlordNote: '${m['landlordNote'] ?? ''}',
        forwardedToVendorId: m['forwardedToVendorId'] as String?,
        forwardChannel: m['forwardChannel'] == null
            ? null
            : enumByName(ForwardChannel.values, m['forwardChannel'], ForwardChannel.email),
        shareTenantContact: m['shareTenantContact'] == true,
        tenantRating: m['tenantRating'] as int?,
        confirmedVisit: parseDate(m['confirmedVisit']),
      );
}
