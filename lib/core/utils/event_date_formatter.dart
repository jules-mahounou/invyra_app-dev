const _monthNames = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

abstract final class EventDateFormatter {
  static String format(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Date à définir';
    }

    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(local.year, local.month, local.day);
    final time =
        '${local.hour.toString().padLeft(2, '0')}h${local.minute.toString().padLeft(2, '0')}';

    if (eventDay == today) {
      return 'Aujourd\'hui • $time';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (eventDay == yesterday) {
      return 'Hier • $time';
    }

    final month = _monthNames[local.month - 1];
    return '${_weekdayShort(local.weekday)} $local.day $month • $time';
  }

  static String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lun';
      case DateTime.tuesday:
        return 'Mar';
      case DateTime.wednesday:
        return 'Mer';
      case DateTime.thursday:
        return 'Jeu';
      case DateTime.friday:
        return 'Ven';
      case DateTime.saturday:
        return 'Sam';
      default:
        return 'Dim';
    }
  }
}
