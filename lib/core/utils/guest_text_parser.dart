/// Une entrée extraite d'une liste d'invités collée en texte libre.
class ParsedGuestEntry {
  final String fullName;
  final String? phone;

  const ParsedGuestEntry({required this.fullName, this.phone});
}

final RegExp _phonePattern = RegExp(r'\+?\d[\d \-.]{5,14}\d');
final RegExp _trimSeparators = RegExp(r'^[\s,:;\-–—]+|[\s,:;\-–—]+$');

/// Analyse un texte collé par l'utilisateur (depuis ses notes, un message
/// WhatsApp reçu, etc.) et en extrait des paires nom/téléphone, sans imposer
/// de format précis. Gère deux styles courants :
///  - une ligne par invité : "Jean Dupont, 97123456" ou "Jean Dupont - 97123456"
///  - deux lignes par invité : le nom sur une ligne, le numéro sur la suivante
///
/// Le résultat est toujours présenté à l'utilisateur dans un aperçu modifiable
/// avant import : cette analyse est une aide, pas une vérité absolue.
List<ParsedGuestEntry> parseGuestListText(String input) {
  final lines = input
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  final results = <ParsedGuestEntry>[];
  String? pendingName;

  void flushPendingName() {
    if (pendingName != null) {
      results.add(ParsedGuestEntry(fullName: pendingName!));
      pendingName = null;
    }
  }

  for (final line in lines) {
    final match = _phonePattern.firstMatch(line);

    if (match == null) {
      // Pas de numéro sur cette ligne : c'est probablement un nom seul.
      flushPendingName();
      pendingName = line;
      continue;
    }

    final phone = match.group(0)!.replaceAll(RegExp(r'[^\d+]'), '');
    final namePart = line
        .replaceFirst(match.group(0)!, '')
        .replaceAll(_trimSeparators, '')
        .trim();

    if (namePart.isNotEmpty) {
      // Nom et numéro sur la même ligne.
      flushPendingName();
      results.add(ParsedGuestEntry(fullName: namePart, phone: phone));
    } else if (pendingName != null) {
      // Numéro seul : associé au nom lu sur la ligne précédente.
      results.add(ParsedGuestEntry(fullName: pendingName!, phone: phone));
      pendingName = null;
    } else {
      // Numéro seul sans nom connu — on le garde, l'utilisateur complétera
      // le nom dans l'aperçu.
      results.add(ParsedGuestEntry(fullName: '', phone: phone));
    }
  }
  flushPendingName();

  return results;
}
