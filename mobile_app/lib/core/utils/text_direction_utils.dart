import 'package:flutter/material.dart';

/// Picks a text direction so Arabic (and related scripts) render correctly in mixed layouts.
TextDirection textDirectionForString(String? text) {
  if (text == null || text.trim().isEmpty) {
    return TextDirection.ltr;
  }
  final hasRtl = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  ).hasMatch(text);
  return hasRtl ? TextDirection.rtl : TextDirection.ltr;
}
