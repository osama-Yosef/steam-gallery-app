import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _currency = NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م', decimalDigits: 2);
  static final _date = DateFormat('yyyy/MM/dd', 'ar');
  static final _dateTime = DateFormat('yyyy/MM/dd  hh:mm a', 'ar');

  static String currency(num amount) => _currency.format(amount);
  static String date(DateTime dt) => _date.format(dt.toLocal());
  static String dateTime(DateTime dt) => _dateTime.format(dt.toLocal());
}
