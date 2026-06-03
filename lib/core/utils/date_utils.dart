import 'package:intl/intl.dart';

String formatEventDate(dynamic rawDate) {
  if (rawDate == null) return 'Date non définie';
  try {
    final date = rawDate is DateTime
        ? rawDate
        : DateTime.parse(rawDate as String);
    return DateFormat("d MMMM yyyy 'à' HH:mm", 'fr').format(date.toLocal());
  } catch (_) {
    return 'Date invalide';
  }
}

String formatEventDateShort(dynamic rawDate) {
  if (rawDate == null) return 'Date non définie';
  try {
    final date = rawDate is DateTime
        ? rawDate
        : DateTime.parse(rawDate as String);
    return DateFormat('d MMM yyyy', 'fr').format(date.toLocal());
  } catch (_) {
    return 'Date invalide';
  }
}
