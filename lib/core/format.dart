import 'package:intl/intl.dart';

/// Indian-locale money. Renders 250000 as "₹2,50,000" (lakh grouping), which is
/// what an Indian user expects — `en_US` would render "₹250,000".
final _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '\u20B9',
  decimalDigits: 0,
);

String formatMoney(num? amount) {
  if (amount == null) return 'Not specified';
  return _rupees.format(amount);
}

/// "Budget" on a job card. Families often leave it blank on purpose.
String formatBudget(num? amount) {
  if (amount == null) return 'Open to quotes';
  return formatMoney(amount);
}

final _dayMonth = DateFormat('d MMM');
final _dayMonthYear = DateFormat('d MMM yyyy');

String formatDate(DateTime? d) {
  if (d == null) return '';
  return d.year == DateTime.now().year ? _dayMonth.format(d) : _dayMonthYear.format(d);
}

/// A ritual may run over several days (Vivaha), so a job shows a range.
String formatDateRange(DateTime start, DateTime? end) {
  if (end == null || end == start) return formatDate(start);
  return '${formatDate(start)} \u2013 ${formatDate(end)}';
}

/// Upwork-style "Posted 3 hours ago". Deliberately coarse — precision here is
/// noise, and it avoids pulling in another package.
String timeAgo(DateTime when) {
  final diff = DateTime.now().difference(when);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
  final months = diff.inDays ~/ 30;
  if (months < 12) return '$months month${months == 1 ? '' : 's'} ago';
  final years = diff.inDays ~/ 365;
  return '$years year${years == 1 ? '' : 's'} ago';
}

/// Days until a ritual. Negative means the date has passed.
String daysUntil(DateTime date) {
  final today = DateTime.now();
  final d = DateTime(date.year, date.month, date.day)
      .difference(DateTime(today.year, today.month, today.day))
      .inDays;
  if (d < 0) return 'Date passed';
  if (d == 0) return 'Today';
  if (d == 1) return 'Tomorrow';
  return 'In $d days';
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters1();
  return '${parts.first.characters1()}${parts.last.characters1()}';
}

extension on String {
  String characters1() => isEmpty ? '' : substring(0, 1).toUpperCase();
}
