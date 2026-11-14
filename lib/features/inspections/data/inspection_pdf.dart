
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/comparison.dart';
import '../domain/inspection.dart';

/// Text used in the report, so the PDF follows the app's language without
/// depending on BuildContext (and so tests can build one).
class InspectionPdfLabels {
  const InspectionPdfLabels({
    required this.moveIn,
    required this.moveOut,
    required this.property,
    required this.tenant,
    required this.landlord,
    required this.created,
    required this.completed,
    required this.status,
    required this.statuses,
    required this.conditions,
    required this.meters,
    required this.electricity,
    required this.water,
    required this.gas,
    required this.keys,
    required this.keyNames,
    required this.item,
    required this.condition,
    required this.notes,
    required this.comparison,
    required this.atMoveIn,
    required this.atMoveOut,
    required this.worsened,
    required this.noneWorsened,
    required this.videos,
    required this.tenantComments,
    required this.confirmations,
    required this.landlordSigned,
    required this.tenantConfirmed,
    required this.notYet,
    required this.completionNote,
    required this.generalNotes,
    required this.photosOmitted,
    this.rtl = false,
  });

  final String moveIn, moveOut, property, tenant, landlord, created, completed, status;
  final Map<InspectionStatus, String> statuses;
  final Map<Condition, String> conditions;
  final String meters, electricity, water, gas, keys;

  /// mainDoor, mailbox, parking, accessCards, remotes, other.
  final Map<String, String> keyNames;
  final String item, condition, notes, comparison, atMoveIn, atMoveOut, worsened, noneWorsened, videos;
  final String tenantComments, confirmations, landlordSigned, tenantConfirmed, notYet, completionNote, generalNotes;

  /// e.g. "{n} more photos in the app"; {n} is replaced.
  final String photosOmitted;
  final bool rtl;

  static const english = InspectionPdfLabels(
    moveIn: 'Move-in inspection',
    moveOut: 'Move-out inspection',
    property: 'Property',
    tenant: 'Tenant',
    landlord: 'Landlord',
    created: 'Created',
    completed: 'Completed',
    status: 'Status',
    statuses: {
      InspectionStatus.draft: 'Draft',
      InspectionStatus.awaitingTenant: 'Waiting for tenant',
      InspectionStatus.completed: 'Completed',
    },
    conditions: {
      Condition.excellent: 'Excellent',
      Condition.good: 'Good',
      Condition.fair: 'Fair',
      Condition.poor: 'Poor',
      Condition.damaged: 'Damaged',
      Condition.missing: 'Missing',
      Condition.na: 'N/A',
    },
    meters: 'Meter readings',
    electricity: 'Electricity',
    water: 'Water',
    gas: 'Gas',
    keys: 'Keys handed over',
    keyNames: {
      'mainDoor': 'Main door',
      'mailbox': 'Mailbox',
      'parking': 'Parking',
      'accessCards': 'Access cards',
      'remotes': 'Remotes',
      'other': 'Other',
    },
    item: 'Item',
    condition: 'Condition',
    notes: 'Notes',
    comparison: 'Move-in vs move-out',
    atMoveIn: 'Move-in',
    atMoveOut: 'Move-out',
    worsened: 'Items in worse condition',
    noneWorsened: 'No item is in worse condition than at move-in.',
    videos: 'Videos',
    tenantComments: "Tenant's comments",
    confirmations: 'Confirmations',
    landlordSigned: 'Landlord signed',
    tenantConfirmed: 'Tenant confirmed',
    notYet: 'Not yet',
    completionNote: 'Completed without tenant confirmation',
    generalNotes: 'General notes',
    photosOmitted: '{n} more photos in the app',
  );
}

/// Names and addresses printed on the cover.
class InspectionReportInfo {
  const InspectionReportInfo({this.propertyName = '', this.address = '', this.tenantName = '', this.landlordName = ''});
  final String propertyName, address, tenantName, landlordName;
}

/// Loads a photo for the report; returns null when it can't be read.
typedef ImageLoader = Future<Uint8List?> Function(String url);

Future<Uint8List?> defaultImageLoader(String url) async {
  try {
    if (url.startsWith('http')) {
      final data = await NetworkAssetBundle(Uri.parse(url)).load(url);
      return data.buffer.asUint8List();
    }
    return await XFile(url).readAsBytes();
  } catch (_) {
    return null;
  }
}

/// Most photos embedded in one report, to keep the PDF small enough to email.
const maxReportPhotos = 60;

/// Builds the report. [moveIn] adds the comparison section to a move-out.
/// Set [googleFonts] false to skip downloading Noto (tests, offline); Arabic
/// text then can't render, so the app always passes true.
Future<Uint8List> buildInspectionPdf(
  Inspection insp, {
  InspectionReportInfo info = const InspectionReportInfo(),
  Inspection? moveIn,
  InspectionPdfLabels labels = InspectionPdfLabels.english,
  ImageLoader loadImage = defaultImageLoader,
  bool googleFonts = true,
  bool compress = true,
}) async {
  pw.ThemeData? theme;
  if (googleFonts) {
    try {
      final base = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      final arabic = await PdfGoogleFonts.notoSansArabicRegular();
      theme = pw.ThemeData.withFont(base: base, bold: bold, fontFallback: [arabic]);
    } catch (e) {
      debugPrint('Inspection PDF: fonts unavailable ($e); using built-in fonts.');
    }
  }

  final dir = labels.rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  final df = DateFormat('dd/MM/yyyy HH:mm');
  String date(DateTime? d) => d == null ? labels.notYet : df.format(d);
  final amber = PdfColor.fromHex('#B45309');
  final grey = PdfColor.fromHex('#57534E');

  // Load photo thumbnails up front (pw widgets are synchronous).
  var budget = maxReportPhotos;
  final images = <String, pw.ImageProvider>{};
  Future<void> load(Iterable<InspectionMedia> media) async {
    for (final m in media) {
      if (m.isVideo || budget <= 0 || images.containsKey(m.url)) continue;
      final bytes = await loadImage(m.thumbUrl ?? m.url);
      if (bytes != null) {
        try {
          images[m.url] = pw.MemoryImage(bytes);
          budget--;
        } catch (_) {}
      }
    }
  }

  for (final r in insp.rooms) {
    await load(r.media);
    for (final i in r.items) {
      await load(i.media);
    }
  }
  await load(insp.meters.photos);
  await load(insp.tenantMedia);

  pw.Widget heading(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(t, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: amber)),
      );

  pw.Widget kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(width: 130, child: pw.Text(k, style: pw.TextStyle(color: grey))),
          pw.Expanded(child: pw.Text(v.isEmpty ? '-' : v)),
        ]),
      );

  List<pw.Widget> photos(List<InspectionMedia> media) {
    final pics = [for (final m in media) if (images.containsKey(m.url)) images[m.url]!];
    final vids = media.where((m) => m.isVideo).toList();
    final missing = media.where((m) => !m.isVideo && !images.containsKey(m.url)).length;
    return [
      if (pics.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Wrap(spacing: 4, runSpacing: 4, children: [
            for (final p in pics) pw.Container(width: 88, height: 66, child: pw.Image(p, fit: pw.BoxFit.cover)),
          ]),
        ),
      if (missing > 0)
        pw.Text(labels.photosOmitted.replaceAll('{n}', '$missing'), style: pw.TextStyle(fontSize: 8, color: grey)),
      if (vids.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('${labels.videos}:', style: pw.TextStyle(fontSize: 8, color: grey)),
            for (final v in vids)
              v.url.startsWith('http')
                  ? pw.UrlLink(
                      destination: v.url,
                      child: pw.Text(v.url, style: const pw.TextStyle(fontSize: 7, color: PdfColors.blue700)))
                  : pw.Text(v.url, style: pw.TextStyle(fontSize: 7, color: grey)),
          ]),
        ),
    ];
  }

  String cond(Condition? c) => c == null ? '-' : labels.conditions[c]!;

  final comparison = (moveIn != null && insp.isMoveOut) ? compareInspections(moveIn, insp) : const <ItemComparison>[];
  final worse = comparison.where((c) => c.worsened).toList()..sort((a, b) => b.severity.compareTo(a.severity));

  final doc = pw.Document(compress: compress, title: insp.isMoveOut ? labels.moveOut : labels.moveIn);
  doc.addPage(pw.MultiPage(
    theme: theme,
    textDirection: dir,
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    footer: (ctx) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('LedGix Rent · ${ctx.pageNumber}/${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8, color: grey)),
    ),
    build: (ctx) => [
      // Cover
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FEF3C7'), borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(insp.isMoveOut ? labels.moveOut : labels.moveIn,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          kv(labels.property, [info.propertyName, info.address].where((s) => s.isNotEmpty).join(' · ')),
          kv(labels.tenant, info.tenantName),
          kv(labels.landlord, info.landlordName),
          kv(labels.created, date(insp.createdAt)),
          kv(labels.completed, date(insp.completedAt)),
          kv(labels.status, labels.statuses[insp.status]!),
        ]),
      ),
      if (insp.generalNotes.isNotEmpty) ...[heading(labels.generalNotes), pw.Text(insp.generalNotes)],
      heading(labels.meters),
      kv(labels.electricity, insp.meters.electricity),
      kv(labels.water, insp.meters.water),
      if (insp.meters.gas.isNotEmpty) kv(labels.gas, insp.meters.gas),
      ...photos(insp.meters.photos),
      heading(labels.keys),
      for (final e in insp.keys.toMap().entries)
        if ('${e.value}'.isNotEmpty) kv(labels.keyNames[e.key] ?? e.key, '${e.value}'),
      if (insp.keys.isEmpty) pw.Text('-'),
      for (final r in insp.rooms) ...[
        heading(r.name),
        if (r.notes.isNotEmpty) pw.Text(r.notes),
        pw.TableHelper.fromTextArray(
          headers: [labels.item, labels.condition, labels.notes],
          data: [for (final i in r.items) [i.name, cond(i.condition), i.notes]],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(2), 2: const pw.FlexColumnWidth(5)},
        ),
        ...photos(r.media),
        for (final i in r.items)
          if (i.media.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(i.name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ...photos(i.media),
          ],
      ],
      if (moveIn != null && insp.isMoveOut) ...[
        heading(labels.comparison),
        pw.TableHelper.fromTextArray(
          headers: [labels.item, labels.atMoveIn, labels.atMoveOut],
          data: [
            for (final c in comparison) ['${c.roomName} · ${c.itemName}', cond(c.moveIn?.condition), cond(c.moveOut?.condition)],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        ),
        heading(labels.worsened),
        if (worse.isEmpty) pw.Text(labels.noneWorsened),
        for (final c in worse)
          pw.Bullet(
              text: '${c.roomName} · ${c.itemName}: ${cond(c.moveIn?.condition)} → ${cond(c.moveOut?.condition)}'
                  '${(c.moveOut?.notes ?? '').isEmpty ? '' : ' (${c.moveOut!.notes})'}'),
      ],
      if (insp.tenantComments.isNotEmpty || insp.tenantMedia.isNotEmpty) ...[
        heading(labels.tenantComments),
        for (final c in insp.tenantComments) pw.Bullet(text: '${df.format(c.at)}: ${c.text}'),
        ...photos(insp.tenantMedia),
      ],
      heading(labels.confirmations),
      kv(labels.landlordSigned, date(insp.landlordSignedAt)),
      kv(labels.tenantConfirmed, date(insp.tenantConfirmedAt)),
      if (insp.completionNote.isNotEmpty) kv(labels.completionNote, insp.completionNote),
    ],
  ));
  return doc.save();
}

/// Opens the system share/print sheet (download on the web).
Future<void> shareInspectionPdf(Uint8List bytes, String filename) => Printing.sharePdf(bytes: bytes, filename: filename);
