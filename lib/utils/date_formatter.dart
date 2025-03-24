import 'package:intl/intl.dart';

class DateFormatter {
  // Date formatters
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _fullDateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Format a DateTime to date string (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  // Format a DateTime to time string (HH:mm)
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  // Format a DateTime to full date and time string
  static String formatDateTime(DateTime dateTime) {
    return _fullDateTimeFormat.format(dateTime);
  }

  // Try to parse a string to DateTime, with fallback
  static DateTime tryParse(String? dateString, {DateTime? fallback}) {
    if (dateString == null || dateString.isEmpty) {
      return fallback ?? DateTime.now();
    }

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return fallback ?? DateTime.now();
    }
  }
}
