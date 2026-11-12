import '../../../core/domain/entity.dart';
import '../../../core/utils/dates.dart';
import '../../properties/domain/property.dart';
import '../../tenants/domain/tenant.dart';
import '../../vendors/domain/vendor.dart';
import 'maintenance_ticket.dart';

const defaultWorkOrderMessage =
    'Please review this maintenance request and share your quotation and earliest available visit time.';

/// The document sent to a maintenance company when a request is forwarded.
/// Cloud Functions read it to push (app) or email it (see functions/src).
class WorkOrder implements Entity {
  const WorkOrder({
    required this.id,
    required this.ticketId,
    required this.vendorId,
    required this.channel,
    required this.body,
    required this.expiresAt,
    required this.token,
    this.vendorEmail = '',
    this.vendorAccountId,
    this.attachments = const [],
    this.sentAt,
  });

  @override
  final String id;
  final String ticketId, vendorId, body, token, vendorEmail;
  final String? vendorAccountId;
  final ForwardChannel channel;

  /// The secure link used by companies without the app expires at this time.
  final DateTime expiresAt;
  final List<String> attachments;
  final DateTime? sentAt;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'ticketId': ticketId,
        'vendorId': vendorId,
        'channel': channel.name,
        'body': body,
        'token': token,
        'expiresAt': expiresAt.toIso8601String(),
        'vendorEmail': vendorEmail,
        'vendorAccountId': vendorAccountId,
        'attachments': attachments,
        'sentAt': sentAt?.toIso8601String(),
      };

  factory WorkOrder.fromMap(Map<String, dynamic> m) => WorkOrder(
        id: m['id'] as String,
        ticketId: '${m['ticketId']}',
        vendorId: '${m['vendorId']}',
        channel: enumByName(ForwardChannel.values, m['channel'], ForwardChannel.email),
        body: '${m['body'] ?? ''}',
        token: '${m['token'] ?? ''}',
        expiresAt: parseDate(m['expiresAt'])!,
        vendorEmail: '${m['vendorEmail'] ?? ''}',
        vendorAccountId: m['vendorAccountId'] as String?,
        attachments: [for (final a in (m['attachments'] as List? ?? const [])) '$a'],
        sentAt: parseDate(m['sentAt']),
      );
}

class WorkOrderBuilder {
  const WorkOrderBuilder._();

  static const linkLifetime = Duration(days: 7);

  /// Plain-text work order. Tenant contact details only when the landlord allowed it.
  static String text({
    required MaintenanceTicket ticket,
    required Property property,
    Tenant? tenant,
    String? note,
  }) {
    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    final b = StringBuffer()
      ..writeln('WORK ORDER: ${ticket.title}')
      ..writeln()
      ..writeln('Property: ${property.name}')
      ..writeln('Type: ${cap(property.type.name)}');
    if (property.community.isNotEmpty) b.writeln('Area: ${property.community}');
    if (property.address.isNotEmpty) b.writeln('Address: ${property.address}');
    b
      ..writeln()
      ..writeln('Category: ${ticket.category.name}')
      ..writeln('Urgency: ${ticket.priority.name}');
    if (ticket.description.isNotEmpty) b.writeln('Description: ${ticket.description}');
    b.writeln('Photos: ${ticket.photos.length}, videos: ${ticket.videos.length}');
    if (ticket.visitRequired) {
      b.writeln('Visit required: yes');
      for (final s in ticket.timeSlots) {
        b.writeln('  Available: ${formatDate(s)} ${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}');
      }
      if (ticket.accessNotes.isNotEmpty) b.writeln('Access notes: ${ticket.accessNotes}');
    } else {
      b.writeln('Visit required: no');
    }
    if (ticket.shareTenantContact && tenant != null) {
      b.writeln('Tenant: ${tenant.name}${tenant.phone.isEmpty ? '' : ' (${tenant.phone})'}');
    }
    b
      ..writeln()
      ..writeln(note == null || note.trim().isEmpty ? defaultWorkOrderMessage : '${note.trim()}\n$defaultWorkOrderMessage');
    return b.toString().trimRight();
  }

  /// Channel: in-app if the company uses LedGix Rent, otherwise email with a secure link.
  static WorkOrder build({
    required String id,
    required String token,
    required MaintenanceTicket ticket,
    required Property property,
    required Vendor vendor,
    required DateTime now,
    Tenant? tenant,
    String? note,
  }) =>
      WorkOrder(
        id: id,
        ticketId: ticket.id,
        vendorId: vendor.id,
        channel: vendor.usesApp ? ForwardChannel.app : ForwardChannel.email,
        body: text(ticket: ticket, property: property, tenant: tenant, note: note),
        token: token,
        expiresAt: now.add(linkLifetime),
        vendorEmail: vendor.email,
        vendorAccountId: vendor.linkedAccountId,
        attachments: [...ticket.photos, ...ticket.videos],
      );

  /// The vendor a new ticket should go to: the property's default, then the
  /// vendor marked as default for the ticket's category.
  static Vendor? defaultVendor(MaintenanceTicket t, Property p, List<Vendor> vendors) {
    for (final v in vendors) {
      if (v.id == p.defaultVendorId) return v;
    }
    for (final v in vendors) {
      if (v.defaultCategories.contains(t.category.name)) return v;
    }
    return null;
  }
}
