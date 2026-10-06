import 'package:flutter/services.dart';

/// Digits and at most one decimal point — for every money field. A hardware
/// keyboard ignores `keyboardType`, so without this a stray letter on
/// desktop used to sit in the field silently parsing as 0.
final moneyInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'^\d*\.?\d*'),
);
