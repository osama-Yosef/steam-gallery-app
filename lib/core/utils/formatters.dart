import 'package:intl/intl.dart';

abstract final class Formatters {
  // 'ar', not 'ar_EG': the shop reads every number in English digits.
  static final _currency = NumberFormat.currency(
    locale: 'ar',
    symbol: 'ج.م',
    decimalDigits: 2,
  );
  static final _currencyWhole = NumberFormat.currency(
    locale: 'ar',
    symbol: 'ج.م',
    decimalDigits: 0,
  );
  static final _date = DateFormat('yyyy/MM/dd', 'ar');
  static final _dateTime = DateFormat('yyyy/MM/dd  hh:mm a', 'ar');
  static final _month = DateFormat('MMMM yyyy', 'ar');

  /// Whole to the piastre: no ".00" to read past.
  static bool _isWhole(num amount) => (amount * 100).round() % 100 == 0;

  /// `1,500 ج.م`, or `12.50 ج.م` when there are piastres.
  static String currency(num amount) => _isWhole(amount)
      ? _currencyWhole.format(amount)
      : _currency.format(amount);

  /// An amount for a text field to start from: `1500` or `12.50` — no
  /// grouping, so it parses straight back.
  static String plain(num amount) =>
      _isWhole(amount) ? amount.round().toString() : amount.toStringAsFixed(2);

  static String date(DateTime dt) => _date.format(dt.toLocal());
  static String dateTime(DateTime dt) => _dateTime.format(dt.toLocal());
  static String month(DateTime dt) => _month.format(dt.toLocal());
}
