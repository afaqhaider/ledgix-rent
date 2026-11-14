import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../data/inspection_pdf.dart';
import '../domain/inspection.dart';

String conditionLabel(AppLocalizations l, Condition c) => switch (c) {
      Condition.excellent => l.conditionExcellent,
      Condition.good => l.conditionGood,
      Condition.fair => l.conditionFair,
      Condition.poor => l.conditionPoor,
      Condition.damaged => l.conditionDamaged,
      Condition.missing => l.conditionMissing,
      Condition.na => l.conditionNa,
    };

Color conditionColor(BuildContext context, Condition? c) {
  final s = context.status;
  return switch (c) {
    Condition.excellent || Condition.good => s.success,
    Condition.fair => s.info,
    Condition.poor => s.warning,
    Condition.damaged || Condition.missing => s.danger,
    Condition.na || null => s.neutral,
  };
}

IconData conditionIcon(Condition? c) => switch (c) {
      Condition.excellent || Condition.good => Icons.check_circle_outline,
      Condition.fair => Icons.remove_circle_outline,
      Condition.poor => Icons.warning_amber_rounded,
      Condition.damaged => Icons.report_gmailerrorred,
      Condition.missing => Icons.help_outline,
      Condition.na || null => Icons.radio_button_unchecked,
    };

String statusLabel(AppLocalizations l, InspectionStatus s) => switch (s) {
      InspectionStatus.draft => l.inspectionStatusDraft,
      InspectionStatus.awaitingTenant => l.inspectionStatusAwaitingTenant,
      InspectionStatus.completed => l.inspectionStatusCompleted,
    };

Color statusColorOf(BuildContext context, InspectionStatus s) => switch (s) {
      InspectionStatus.draft => context.status.neutral,
      InspectionStatus.awaitingTenant => context.status.warning,
      InspectionStatus.completed => context.status.success,
    };

IconData statusIconOf(InspectionStatus s) => switch (s) {
      InspectionStatus.draft => Icons.edit_note,
      InspectionStatus.awaitingTenant => Icons.hourglass_top,
      InspectionStatus.completed => Icons.verified_outlined,
    };

String typeLabel(AppLocalizations l, InspectionType t) =>
    t == InspectionType.moveIn ? l.moveInInspection : l.moveOutInspection;

IconData typeIcon(InspectionType t) => t == InspectionType.moveIn ? Icons.login : Icons.logout;

/// The PDF's text in the app's current language.
InspectionPdfLabels pdfLabels(BuildContext context) {
  final l = context.l;
  return InspectionPdfLabels(
    moveIn: l.moveInInspection,
    moveOut: l.moveOutInspection,
    property: l.property,
    tenant: l.tenant,
    landlord: l.landlord,
    created: l.createdLabel,
    completed: l.completedLabel,
    status: l.inspectionStatusLabel,
    statuses: {for (final s in InspectionStatus.values) s: statusLabel(l, s)},
    conditions: {for (final c in Condition.values) c: conditionLabel(l, c)},
    meters: l.meterReadings,
    electricity: l.meterElectricity,
    water: l.meterWater,
    gas: l.meterGas,
    keys: l.keysHandedOver,
    keyNames: {
      'mainDoor': l.keysMainDoor,
      'mailbox': l.keysMailbox,
      'parking': l.keysParking,
      'accessCards': l.keysAccessCards,
      'remotes': l.keysRemotes,
      'other': l.keysOther,
    },
    item: l.itemLabel,
    condition: l.conditionLabel,
    notes: l.notes,
    comparison: l.moveInVsMoveOut,
    atMoveIn: l.atMoveIn,
    atMoveOut: l.atMoveOut,
    worsened: l.worsenedItems,
    noneWorsened: l.noWorsenedItems,
    videos: l.videosLabel,
    tenantComments: l.tenantComments,
    confirmations: l.confirmationsLabel,
    landlordSigned: l.landlordSigned,
    tenantConfirmed: l.tenantConfirmed,
    notYet: l.notYet,
    completionNote: l.completedWithoutTenant,
    generalNotes: l.generalNotes,
    photosOmitted: l.photosOmitted(999).replaceAll('999', '{n}'),
    rtl: Directionality.of(context) == TextDirection.rtl,
  );
}

/// Media is a download URL in production and a local path (or blob URL on
/// the web) in demo mode.
bool _isRemote(String url) => kIsWeb || url.startsWith('http') || url.startsWith('blob:');

ImageProvider mediaImage(String url) => _isRemote(url) ? NetworkImage(url) : FileImage(File(url)) as ImageProvider;

/// Square thumbnail; videos show a play badge.
class MediaThumb extends StatelessWidget {
  const MediaThumb(this.media, {super.key, this.size = 72, this.onTap, this.onRemove});
  final InspectionMedia media;
  final double size;
  final VoidCallback? onTap, onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumb = media.thumbUrl ?? media.url;
    return SizedBox.square(
      dimension: size,
      child: Stack(fit: StackFit.expand, children: [
        Material(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(10),
          color: scheme.surfaceContainerHighest,
          child: InkWell(
            onTap: onTap,
            child: media.isVideo && media.thumbUrl == null
                ? Icon(Icons.videocam_outlined, color: scheme.onSurfaceVariant)
                : Image(
                    image: mediaImage(thumb),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
                  ),
          ),
        ),
        if (media.isVideo)
          const Center(
            child: IgnorePointer(
              child: CircleAvatar(radius: 14, backgroundColor: Colors.black54, child: Icon(Icons.play_arrow, color: Colors.white, size: 18)),
            ),
          ),
        if (media.by == MediaBy.tenant)
          PositionedDirectional(
            start: 4,
            bottom: 4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: scheme.tertiary, borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.person, size: 12, color: scheme.onTertiary),
              ),
            ),
          ),
        if (onRemove != null)
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: context.l.delete,
              style: IconButton.styleFrom(backgroundColor: Colors.black45, foregroundColor: Colors.white, minimumSize: const Size(24, 24)),
              iconSize: 14,
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ),
      ]),
    );
  }
}

/// Wrapping strip of thumbnails that opens the full-screen viewer.
class MediaStrip extends StatelessWidget {
  const MediaStrip(this.media, {super.key, this.size = 72, this.onRemove, this.trailing = const []});
  final List<InspectionMedia> media;
  final double size;
  final void Function(InspectionMedia m)? onRemove;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty && trailing.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (var i = 0; i < media.length; i++)
        MediaThumb(
          media[i],
          size: size,
          onTap: () => openMediaViewer(context, media, i),
          onRemove: onRemove == null ? null : () => onRemove!(media[i]),
        ),
      ...trailing,
    ]);
  }
}

Future<void> openMediaViewer(BuildContext context, List<InspectionMedia> media, int index) =>
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _MediaViewer(media: media, initial: index),
    ));

class _MediaViewer extends StatefulWidget {
  const _MediaViewer({required this.media, required this.initial});
  final List<InspectionMedia> media;
  final int initial;
  @override
  State<_MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<_MediaViewer> {
  late final _page = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.media[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.media.length}'),
        bottom: m.takenAt == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(formatDateTime(m.takenAt!), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
      ),
      body: PageView.builder(
        controller: _page,
        itemCount: widget.media.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final it = widget.media[i];
          return it.isVideo
              ? _VideoPlayer(url: it.url)
              : InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                    child: Image(
                      image: mediaImage(it.url),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                    ),
                  ),
                );
        },
      ),
    );
  }
}

String formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

class _VideoPlayer extends StatefulWidget {
  const _VideoPlayer({required this.url});
  final String url;
  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late final VideoPlayerController _c = _isRemote(widget.url)
      ? VideoPlayerController.networkUrl(Uri.parse(widget.url))
      : VideoPlayerController.file(File(widget.url));
  Object? _error;

  @override
  void initState() {
    super.initState();
    _c.initialize().then((_) {
      if (mounted) setState(() {});
      _c.play();
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e);
    });
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const Center(child: Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 48));
    }
    if (!_c.value.isInitialized) return const Center(child: CircularProgressIndicator());
    return Column(children: [
      Expanded(child: Center(child: AspectRatio(aspectRatio: _c.value.aspectRatio, child: VideoPlayer(_c)))),
      VideoProgressIndicator(_c, allowScrubbing: true, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
      IconButton(
        color: Colors.white,
        iconSize: 40,
        onPressed: () => _c.value.isPlaying ? _c.pause() : _c.play(),
        icon: Icon(_c.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
      ),
      const SizedBox(height: 16),
    ]);
  }
}

/// Small coloured chip showing a condition (or "-" when unrated).
class ConditionBadge extends StatelessWidget {
  const ConditionBadge(this.condition, {super.key});
  final Condition? condition;

  @override
  Widget build(BuildContext context) => condition == null
      ? Text('—', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
      : StatusChip(conditionLabel(context.l, condition!), conditionColor(context, condition), icon: conditionIcon(condition));
}
