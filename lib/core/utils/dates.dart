import 'package:intl/intl.dart';

/// Gulf Standard Time is UTC+4 with no daylight saving.
const gstOffset = Duration(hours: 4);

DateTime nowGst() => DateTime.now().toUtc().add(gstOffset);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime todayGst() => dateOnly(nowGst());

/// Adds [months] keeping the day where possible (31 Jan + 1 month = 28/29 Feb).
DateTime addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final year = d.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > lastDay ? lastDay : d.day);
}

final _dmy = DateFormat('dd/MM/yyyy');
String formatDate(DateTime d) => _dmy.format(d);

String formatAed(num v) => 'AED ${NumberFormat('#,##0.00').format(v)}';
