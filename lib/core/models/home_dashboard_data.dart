import 'recent_event.dart';

/// Pack d'invités supplémentaires vendu à l'unité (table `flex_packs`).
class HomeFlexPack {
  final int guestLimit;
  final int priceFcfa;

  const HomeFlexPack({required this.guestLimit, required this.priceFcfa});
}

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

  /// Nom commercial de l'offre actuelle (ex. « Découverte »).
  final String? planName;

  /// Prix mensuel de l'offre Essentiel, pour l'incitation à passer à l'offre payante.
  final int? essentielPriceFcfa;
  final List<HomeFlexPack> flexPacks;

  const HomeDashboardData({
    this.planName,
    this.essentielPriceFcfa,
    this.flexPacks = const [],
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
