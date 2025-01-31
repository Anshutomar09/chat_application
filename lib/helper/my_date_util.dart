import 'package:flutter/material.dart';

class MyDateUtil {
  static String getFormatteTime({required context, required String time}) {
    final date = DateTime.fromMillisecondsSinceEpoch((int.parse(time)));

    return TimeOfDay.fromDateTime(date).format(context);
  }
}
