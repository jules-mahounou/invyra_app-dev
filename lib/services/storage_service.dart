import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _client = Supabase.instance.client;

  /// `image_picker` ne limite que les dimensions, pas le poids du fichier
  /// (ex: un PNG/HEIC de petite résolution mais très compressé peut rester
  /// lourd) : on vérifie donc le poids ici avant de tenter l'upload, pour
  /// échouer vite avec un message clair plutôt qu'un timeout réseau opaque.
  static const int maxFileSizeBytes = 8 * 1024 * 1024; // 8 Mo

  // Upload logo → retourne l'URL publique
  // Chemin dans le bucket : {userId}/{eventId}/{fileName}
  Future<String?> uploadEventLogo({
    required String userId,
    required String eventId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    if (fileBytes.lengthInBytes > maxFileSizeBytes) {
      throw Exception(
        'Image trop volumineuse (max ${maxFileSizeBytes ~/ (1024 * 1024)} Mo).',
      );
    }
    try {
      final String path = '$userId/$eventId/$fileName';

      await _client.storage.from('event-logos').uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final String publicUrl = _client.storage.from('event-logos').getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Erreur de stockage : ${e.message}');
    } catch (e) {
      throw Exception('Impossible d\'uploader le logo. Vérifiez votre connexion.');
    }
  }

  Future<void> deleteEventLogo(String filePath) async {
    try {
      await _client.storage.from('event-logos').remove([filePath]);
    } on StorageException catch (e) {
      throw Exception('Erreur lors de la suppression du logo : ${e.message}');
    } catch (e) {
      throw Exception('Connexion impossible. Vérifiez votre connexion internet.');
    }
  }
}