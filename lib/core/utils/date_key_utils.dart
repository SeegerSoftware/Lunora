import 'package:intl/intl.dart';

abstract final class DateKeyUtils {
  static String todayKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));
  }

  /// Parse `yyyy-MM-dd` en date locale minuit.
  static DateTime parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      throw FormatException('dateKey invalide: $dateKey');
    }
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return DateTime(y, m, d);
  }

  static int calendarDaysBetween(DateTime start, DateTime end) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    return b.difference(a).inDays;
  }
}
