import 'package:intl/intl.dart';

/// Indian Rupee currency formatter (₹1,23,456.78 grouping).
final _currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

final _compact = NumberFormat.compactCurrency(
  locale: 'en_IN',
  symbol: '₹',
);

final _dateFmt = DateFormat('dd MMM yyyy');
final _monthFmt = DateFormat('MMM yy');

String money(double value) => _currency.format(value);

String moneyCompact(double value) => _compact.format(value);

String formatDate(DateTime d) => _dateFmt.format(d);

String formatMonth(DateTime d) => _monthFmt.format(d);

String percent(double value) => '${value.toStringAsFixed(0)}%';
