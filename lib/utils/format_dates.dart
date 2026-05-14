import 'package:intl/intl.dart';

class FormatDates {
  static String dateToString({
    required DateTime date,
    String formato = 'd/MM/yy - HH:mm',
  }) {
    return DateFormat(formato, 'es').format(date);
  }

  static String show(String date) {
    final formatter = DateFormat('EEE, d MMM yyyy HH:mm');
    final dateTime = formatter.parse(date);
    return DateFormat('d/MM/yyyy - HH:mm').format(dateTime);
  }

  /*static String dateToString(DateTime date) {
    final formatter = DateFormat('d/MM/yy - HH:mm');
    return formatter.format(date);
  }*/

  static DateTime toDate(String date) {
    final formatter = DateFormat('EEE, d MMM yyyy HH:mm');
    return formatter.parse(date);
  }
}
