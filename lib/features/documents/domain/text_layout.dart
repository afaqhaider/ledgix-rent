/// One recognised line of text and where it sits on the page.
class OcrLine {
  const OcrLine(this.text, this.left, this.top, this.right, this.bottom);
  final String text;
  final double left, top, right, bottom;
  double get centerY => (top + bottom) / 2;
  double get height => bottom - top;
}

/// Separator between pieces of text that sat side by side on the page.
const segmentGap = '  ';

/// Rebuilds printed rows from OCR lines: lines whose vertical centres line up
/// are joined left to right with [segmentGap]. Labels and their values on
/// forms (Ejari, title deed) usually come back as separate lines, so this puts
/// "Plot No:" and "419" back on one row.
List<String> rowsFromLines(List<OcrLine> lines) {
  final sorted = [...lines.where((l) => l.text.trim().isNotEmpty)]..sort((a, b) => a.centerY.compareTo(b.centerY));
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    final row = rows.isEmpty ? null : rows.last;
    if (row != null) {
      final rowCenter = row.map((l) => l.centerY).reduce((a, b) => a + b) / row.length;
      final rowHeight = row.map((l) => l.height).reduce((a, b) => a > b ? a : b);
      final tolerance = 0.55 * (line.height < rowHeight ? line.height : rowHeight);
      if ((line.centerY - rowCenter).abs() <= tolerance) {
        row.add(line);
        continue;
      }
    }
    rows.add([line]);
  }
  return [
    for (final row in rows) (row..sort((a, b) => a.left.compareTo(b.left))).map((l) => l.text.trim()).join(segmentGap),
  ];
}
