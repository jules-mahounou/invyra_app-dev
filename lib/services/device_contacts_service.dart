import 'package:flutter_contacts/flutter_contacts.dart';

class DeviceContactsService {
  /// Demande la permission d'accès aux contacts (lecture seule).
  Future<bool> requestPermission() {
    return FlutterContacts.requestPermission(readonly: true);
  }

  /// Récupère tous les contacts du téléphone qui ont au moins un numéro de
  /// téléphone (les autres ne sont pas exploitables pour l'envoi d'invitations).
  Future<List<Contact>> getContactsWithPhone() async {
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    return contacts.where((c) => c.phones.isNotEmpty).toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  }
}
