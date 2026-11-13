// PLACEHOLDER (tenant-side branch). The inspections branch owns this file
// and its real implementation; when merging, take the inspections version.
import 'package:material_ui/material_ui.dart';

/// Renders one inspection (move-in / move-out walkthrough).
class InspectionView extends StatelessWidget {
  const InspectionView({super.key, required this.data, required this.tenantMode});
  final Map<String, dynamic> data;
  final bool tenantMode;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final e in data.entries)
            if (e.value is String || e.value is num) ListTile(title: Text(e.key), subtitle: Text('${e.value}')),
        ],
      );
}
