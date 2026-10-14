/// Configuration des mises à jour, injectée au build par la CI
/// (`--dart-define=RELEASE_URL=...` et `--dart-define=UPDATE_CHANNEL=...`).
abstract final class ReleaseConfig {
  /// URL du `version.json` du canal. Vide en local : la vérification est désactivée.
  static const String releaseUrl = String.fromEnvironment('RELEASE_URL');

  /// `dev` ou `stable`.
  static const String channel = String.fromEnvironment('UPDATE_CHANNEL', defaultValue: 'local');

  static bool get isEnabled => releaseUrl.isNotEmpty;
}
