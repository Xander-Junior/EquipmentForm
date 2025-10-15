import 'package:flutter/services.dart';

class UppercaseFormatter extends TextInputFormatter {
  const UppercaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    return TextEditingValue(
      text: upper,
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}
