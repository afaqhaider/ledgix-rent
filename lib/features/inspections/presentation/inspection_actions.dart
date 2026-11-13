import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
import '../../landlord/presentation/onboarding_screen.dart' show landlordProvider;
import '../../leases/domain/lease.dart';
import '../../properties/domain/property.dart';
import '../data/inspection_media.dart';
import '../data/inspection_pdf.dart';
import '../domain/comparison.dart';
import '../domain/inspection.dart';
import '../domain/templates.dart';
import 'inspection_ui.dart';

/// Picks photos/videos; replaced in tests.
typedef MediaPicker = Future<List<(XFile, MediaType)>> Function(BuildContext context);
final inspectionMediaPickerProvider = Provider<MediaPicker>((_) => pickInspectionMedia);

/// Lets the landlord or tenant take a photo, record a video (max 2 min) or
/// pick several from the gallery. Photos are scaled to 1600 px.
Future<List<(XFile, MediaType)>> pickInspectionMedia(BuildContext context) async {
  final l = context.l;
  final choice = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(key: const Key('pick-photo'), leading: const Icon(Icons.photo_camera_outlined), title: Text(l.takePhoto), onTap: () => Navigator.pop(c, 0)),
        ListTile(key: const Key('pick-video'), leading: const Icon(Icons.videocam_outlined), title: Text(l.recordVideo), onTap: () => Navigator.pop(c, 1)),
        ListTile(key: const Key('pick-gallery'), leading: const Icon(Icons.photo_library_outlined), title: Text(l.fromGallery), onTap: () => Navigator.pop(c, 2)),
      ]),
    ),
  );
  final picker = ImagePicker();
  switch (choice) {
    case 0:
      final f = await picker.pickImage(
          source: ImageSource.camera, maxWidth: inspectionPhotoMaxSide, maxHeight: inspectionPhotoMaxSide, imageQuality: 82);
      return f == null ? const [] : [(f, MediaType.photo)];
    case 1:
      final f = await picker.pickVideo(source: ImageSource.camera, maxDuration: maxInspectionVideo);
      return f == null ? const [] : [(f, MediaType.video)];
    case 2:
      final files = await picker.pickMultipleMedia(
          maxWidth: inspectionPhotoMaxSide, maxHeight: inspectionPhotoMaxSide, imageQuality: 82);
      return [for (final f in files) (f, isVideoFile(f) ? MediaType.video : MediaType.photo)];
    default:
      return const [];
  }
}

bool isVideoFile(XFile f) {
  final mime = f.mimeType ?? '';
  if (mime.startsWith('video/')) return true;
  final n = (f.name.isNotEmpty ? f.name : f.path).toLowerCase();
  return const ['.mp4', '.mov', '.m4v', '.webm', '.3gp', '.avi'].any(n.endsWith);
}

/// The move-in a move-out is compared with: the completed one if any,
/// otherwise the most recent move-in for that agreement.
Inspection? moveInFor(Iterable<Inspection> all, String leaseId, {String? preferId}) {
  final ins = all.where((i) => i.leaseId == leaseId && i.type == InspectionType.moveIn).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (preferId != null) {
    for (final i in ins) {
      if (i.id == preferId) return i;
    }
  }
  return ins.where((i) => i.status == InspectionStatus.completed).firstOrNull ?? ins.firstOrNull;
}

InspectionReportInfo reportInfoFor(WidgetRef ref, Inspection i) {
  final p = (ref.read(propertiesProvider).value ?? const <Property>[]).where((p) => p.id == i.propertyId).firstOrNull;
  final t = (ref.read(tenantsProvider).value ?? const []).where((t) => t.id == i.tenantId).firstOrNull;
  final ll = ref.read(landlordProvider).value;
  return InspectionReportInfo(
    propertyName: p?.name ?? '',
    address: p?.address ?? '',
    tenantName: t?.name ?? '',
    landlordName: ll?.name ?? '',
  );
}

/// Builds the PDF and opens the share/print sheet (a download on the web).
Future<void> shareInspectionReport(
  BuildContext context,
  Inspection insp, {
  required InspectionReportInfo info,
  Inspection? moveIn,
}) async {
  final labels = pdfLabels(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await buildInspectionPdf(insp, info: info, moveIn: moveIn, labels: labels);
    final kind = insp.isMoveOut ? 'move-out' : 'move-in';
    final name = info.propertyName.isEmpty ? 'inspection' : info.propertyName.replaceAll(RegExp(r'[^\w\- ]'), '').trim();
    await shareInspectionPdf(bytes, '$name $kind ${insp.createdAt.toIso8601String().substring(0, 10)}.pdf');
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$e')));
  }
}

/// Opens the draft for [lease] and [type] if one exists; otherwise creates
/// it (copying rooms from the move-in for a move-out, or asking how many
/// bedrooms and bathrooms for a move-in) and opens it.
Future<void> startInspection(BuildContext context, WidgetRef ref, Lease lease, InspectionType type) async {
  final all = ref.read(inspectionsProvider).value ?? const <Inspection>[];
  final draft = all.where((i) => i.leaseId == lease.id && i.type == type && i.status == InspectionStatus.draft).firstOrNull;
  if (draft != null) {
    context.push('/inspections/${draft.id}');
    return;
  }
  final property = (ref.read(propertiesProvider).value ?? const <Property>[]).where((p) => p.id == lease.propertyId).firstOrNull;
  final lang = Localizations.localeOf(context).languageCode;
  final moveIn = type == InspectionType.moveOut ? moveInFor(all, lease.id) : null;

  List<InspectionRoom> rooms;
  if (moveIn != null && moveIn.rooms.isNotEmpty) {
    rooms = moveOutRoomsFrom(moveIn);
  } else {
    final layout = await _askLayout(context, property?.type ?? PropertyType.apartment);
    if (layout == null || !context.mounted) return;
    rooms = buildRooms(property?.type ?? PropertyType.apartment,
        bedrooms: layout.bedrooms, bathrooms: layout.bathrooms, lang: lang, newId: newId);
  }
  final insp = Inspection(
    id: newId(),
    leaseId: lease.id,
    propertyId: lease.propertyId,
    tenantId: lease.tenantId,
    type: type,
    createdAt: nowGst(),
    rooms: rooms,
    moveInId: moveIn?.id,
  );
  await ref.read(inspectionRepositoryProvider).save(insp);
  if (context.mounted) context.push('/inspections/${insp.id}');
}

Future<({int bedrooms, int bathrooms})?> _askLayout(BuildContext context, PropertyType type) {
  final d = defaultLayout(type);
  var beds = d.bedrooms, baths = d.bathrooms;
  return showDialog<({int bedrooms, int bathrooms})>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) {
        Widget stepper(String label, int v, ValueChanged<int> on, String key) => Row(children: [
              Expanded(child: Text(label)),
              IconButton(key: Key('$key-minus'), onPressed: v > 0 ? () => set(() => on(v - 1)) : null, icon: const Icon(Icons.remove_circle_outline)),
              SizedBox(width: 28, child: Text('$v', textAlign: TextAlign.center, style: Theme.of(c).textTheme.titleMedium)),
              IconButton(key: Key('$key-plus'), onPressed: v < 12 ? () => set(() => on(v + 1)) : null, icon: const Icon(Icons.add_circle_outline)),
            ]);
        return AlertDialog(
          title: Text(c.l.roomsToInclude),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            stepper(c.l.bedroomsLabel, beds, (v) => beds = v, 'bedrooms'),
            stepper(c.l.bathroomsLabel, baths, (v) => baths = v, 'bathrooms'),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(c.l.cancel)),
            FilledButton(
              key: const Key('start-inspection'),
              onPressed: () => Navigator.pop(c, (bedrooms: beds, bathrooms: baths)),
              child: Text(c.l.startInspection),
            ),
          ],
        );
      },
    ),
  );
}

/// Asks for a short text (room or item name, comment, completion note).
Future<String?> askText(BuildContext context, {required String title, required String label, String initial = '', int maxLines = 1}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        key: const Key('ask-text'),
        controller: c,
        autofocus: true,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        onSubmitted: maxLines == 1 ? (v) => Navigator.pop(d, v.trim()) : null,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: Text(d.l.cancel)),
        FilledButton(key: const Key('ask-text-ok'), onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(d.l.save)),
      ],
    ),
  ).then((v) => (v == null || v.isEmpty) ? null : v);
}
