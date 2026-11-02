import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormatIndo = DateFormat('dd MMMM yyyy', 'id_ID');
  static final DateFormat _dateTimeFormatIndo = DateFormat('dd MMM yyyy HH:mm:ss', 'id_ID');
  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');

  static String formatIndo(DateTime date) {
    try {
      return _dateFormatIndo.format(date);
    } catch (_) {
      // Fallback if locale data is not loaded
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  static String formatDateTimeIndo(DateTime date) {
    try {
      return _dateTimeFormatIndo.format(date);
    } catch (_) {
      return '${formatIndo(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    }
  }

  static String formatShort(DateTime date) {
    return _shortDate.format(date);
  }
}
