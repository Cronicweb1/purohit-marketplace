import 'package:intl/intl.dart';

import 'l10n/app_strings.dart';
import 'l10n/strings_en.dart';

/// Indian-locale money. Renders 250000 as "₹2,50,000" (lakh grouping), which is
/// what an Indian user expects — `en_US` would render "₹250,000".
///
/// Note: the digits and the lakh grouping are correct for Hindi too, so the
/// number format itself is never swapped — only the surrounding words are.
final _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '\u20B9',
  decimalDigits: 0,
);

/// Every helper below takes an optional [AppStrings]. Passing nothing keeps the
/// original English output, which is what the unit tests (and any non-UI
/// caller) rely on; UI call sites pass `ref.watch(stringsProvider)`.
String formatMoney(num? amount, [AppStrings? t]) {
  if (amount == null) return (t ?? const AppStringsEn()).notSpecified;
  return _rupees.format(amount);
}

/// "Budget" on a job card. Families often leave it blank on purpose.
String formatBudget(num? amount, [AppStrings? t]) {
  if (amount == null) return (t ?? const AppStringsEn()).openToQuotes;
  return formatMoney(amount, t);
}

final _dayMonth = DateFormat('d MMM');
final _dayMonthYear = DateFormat('d MMM yyyy');

/// Dates stay in `d MMM` form in both languages: a Devanagari month name needs
/// `initializeDateFormatting('hi')` at startup, which is a separate change.
String formatDate(DateTime? d) {
  if (d == null) return '';
  return d.year == DateTime.now().year ? _dayMonth.format(d) : _dayMonthYear.format(d);
}

/// Whole years elapsed, birthday-aware. Shown next to a date of birth so a
/// reviewer does not have to do the arithmetic in their head.
int ageFrom(DateTime dob, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var years = today.year - dob.year;
  final hadBirthday = today.month > dob.month ||
      (today.month == dob.month && today.day >= dob.day);
  if (!hadBirthday) years -= 1;
  return years;
}

/// A ritual may run over several days (Vivaha), so a job shows a range.
String formatDateRange(DateTime start, DateTime? end) {
  if (end == null || end == start) return formatDate(start);
  return '${formatDate(start)} \u2013 ${formatDate(end)}';
}

/// Upwork-style "Posted 3 hours ago". Deliberately coarse — precision here is
/// noise, and it avoids pulling in another package.
String timeAgo(DateTime when, [AppStrings? t]) {
  final s = t ?? const AppStringsEn();
  final diff = DateTime.now().difference(when);

  if (diff.inSeconds < 60) return s.justNow;
  if (diff.inMinutes < 60) return s.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return s.hoursAgo(diff.inHours);
  if (diff.inDays < 30) return s.daysAgo(diff.inDays);
  final months = diff.inDays ~/ 30;
  if (months < 12) return s.monthsAgo(months);
  return s.yearsAgo(diff.inDays ~/ 365);
}

/// Days until a ritual. Negative means the date has passed.
String daysUntil(DateTime date, [AppStrings? t]) {
  final s = t ?? const AppStringsEn();
  final today = DateTime.now();
  final d = DateTime(date.year, date.month, date.day)
      .difference(DateTime(today.year, today.month, today.day))
      .inDays;
  if (d < 0) return s.datePassed;
  if (d == 0) return s.todayLabel;
  if (d == 1) return s.tomorrowLabel;
  return s.inDaysLabel(d);
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
