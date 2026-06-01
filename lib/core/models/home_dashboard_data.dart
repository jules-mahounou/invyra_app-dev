import 'recent_event.dart';

class HomeDashboardData {
  final String userName;
  final String accountType;
  final String? avatarUrl;
  final String planCode;
  final int? maxEvents;
  final int activeEvents;
  final int guestsConfirmed;
  final int invitesDispatched;
  final int quotaUsed;
  final List<RecentEvent> recentEvents;

  const HomeDashboardData({
    required this.userName,
    required this.accountType,
    this.avatarUrl,
    required this.planCode,
    this.maxEvents,
    required this.activeEvents,
    required this.guestsConfirmed,
    required this.invitesDispatched,
    required this.quotaUsed,
    required this.recentEvents,
  });

  bool get hasUnlimitedEvents => maxEvents == null;

  int get quotaTotal => maxEvents ?? quotaUsed;

  String get firstName {
    final trimmed = userName.trim();
    if (trimmed.isEmpty) {
      return 'Organisateur';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
