import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// What to tell the person when a save fails. A database refusal (a missing
/// column, a value it does not accept, a permission rule) is not a connection
/// problem, so it says what the database said instead of blaming the network.
String saveErrorText(Object error) {
  debugPrint('Save failed: $error');
  if (error is PostgrestException) {
    final detail = error.message.trim();
    return detail.isEmpty
        ? 'Couldn\u2019t save (database error ${error.code ?? 'unknown'}).'
        : 'Couldn\u2019t save: $detail';
  }
  return 'Couldn\u2019t save. Check your connection and try again.';
}
