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

abstract final class NotificationTimeFormatter {
  static String format(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return "À l'instant";
    }
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    }

    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);
    if (date == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    }

    return '${local.day} ${_monthNames[local.month - 1]}';
  }
}
