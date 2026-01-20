import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<String?> pickDate(BuildContext context,
    {DateTime? initialDate}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: DateTime(1950),
    lastDate: DateTime(2100),
  );

  if (picked == null) return null;
  return DateFormat('yyyy-MM-dd').format(picked);
}
