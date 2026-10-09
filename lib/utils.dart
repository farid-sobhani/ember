import 'dart:math';

const monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];
const monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
DateTime today() => dateOnly(DateTime.now());
DateTime startOfWeek(DateTime d) => addDays(dateOnly(d), -(d.weekday - 1));
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _two(int n) => n.toString().padLeft(2, '0');
String dayKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
DateTime parseDayKey(String k) {
  final p = k.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String shortDate(DateTime d) => '${monthShort[d.month - 1]} ${d.day}';
String fullDate(DateTime d) =>
    '${weekdayShort[d.weekday - 1]}, ${monthShort[d.month - 1]} ${d.day}, ${d.year}';
String monthTitle(DateTime d) => '${monthNames[d.month - 1]} ${d.year}';

String prettyDate(DateTime d) {
  final t = today();
  if (sameDay(d, t)) return 'Today';
  if (sameDay(d, addDays(t, -1))) return 'Yesterday';
  if (sameDay(d, addDays(t, 1))) return 'Tomorrow';
  return '${weekdayShort[d.weekday - 1]}, ${shortDate(d)}';
}

String _group(String digits) {
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
    b.write(digits[i]);
  }
  return b.toString();
}

/// 1234.0 -> "1,234", 2.5 -> "2.5"
String fmtNum(double v) {
  final neg = v < 0;
  v = v.abs();
  final s = (v - v.roundToDouble()).abs() < 0.05
      ? v.round().toString()
      : v.toStringAsFixed(1);
  final parts = s.split('.');
  var r = _group(parts[0]);
  if (parts.length > 1) r += '.${parts[1]}';
  return neg ? '-$r' : r;
}

/// 1500 -> "1.5k"
String compactNum(double v) {
  if (v >= 1000) {
    final k = v / 1000;
    return '${k == k.roundToDouble() ? k.toInt() : k.toStringAsFixed(1)}k';
  }
  return v.round().toString();
}

double niceMax(double m) {
  if (m <= 0) return 500;
  final raw = m * 1.12;
  final mag = pow(10, (log(raw) / ln10).floor()).toDouble();
  final n = raw / mag;
  final nice = n <= 1 ? 1 : n <= 2 ? 2 : n <= 2.5 ? 2.5 : n <= 5 ? 5 : 10;
  return nice * mag;
}

/// Accepts Western, Persian and Arabic digits.
double? parseNum(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch in s.trim().split('')) {
    final i = fa.indexOf(ch);
    final j = ar.indexOf(ch);
    if (i >= 0) {
      b.write(i);
    } else if (j >= 0) {
      b.write(j);
    } else if (ch == '٫' || ch == ',') {
      b.write('.');
    } else {
      b.write(ch);
    }
  }
  return double.tryParse(b.toString());
}
