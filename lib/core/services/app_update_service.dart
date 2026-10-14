// Vérifie le `version.json` publié par la CI et installe la nouvelle version (Android).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/release_config.dart';

class AppUpdateInfo {
  final String versionName;
  final int versionCode;
  final String currentVersionName;
  final String notes;
  final bool mandatory;
  final String apkUrl;

  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.currentVersionName,
    required this.notes,
    required this.mandatory,
    required this.apkUrl,
  });
}

class AppUpdateCheckResult {
  /// Mise à jour disponible, ou `null` si déjà à jour / vérification impossible.
  final AppUpdateInfo? update;

  /// Message lisible quand la vérification n'a pas pu se faire.
  final String? error;

  const AppUpdateCheckResult({this.update, this.error});
}

class AppUpdateService {
  /// Ne lève jamais d'exception : on ne bloque jamais l'utilisateur.
  Future<AppUpdateCheckResult> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const AppUpdateCheckResult(error: 'Mise à jour automatique disponible sur Android uniquement.');
    }
    if (!ReleaseConfig.isEnabled) {
      return const AppUpdateCheckResult(error: 'Build local : mise à jour automatique désactivée.');
    }

    try {
      final response = await http
          .get(Uri.parse(ReleaseConfig.releaseUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return AppUpdateCheckResult(error: 'Serveur de mise à jour injoignable (${response.statusCode}).');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final remoteCode = (data['versionCode'] as num?)?.toInt() ?? 0;

      final package = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(package.buildNumber) ?? 0;
      if (remoteCode <= currentCode) return const AppUpdateCheckResult();

      final apks = (data['apks'] as Map?)?.cast<String, dynamic>() ?? const {};
      final apkUrl = apks[_deviceAbi()] as String? ?? apks['arm64-v8a'] as String?;
      if (apkUrl == null) {
        return const AppUpdateCheckResult(error: 'Aucun APK compatible avec ce téléphone.');
      }

      return AppUpdateCheckResult(
        update: AppUpdateInfo(
        versionName: data['versionName'] as String? ?? '',
        versionCode: remoteCode,
        currentVersionName: '${package.version} (${package.buildNumber})',
        notes: data['notes'] as String? ?? '',
        mandatory: data['mandatory'] as bool? ?? false,
          apkUrl: apkUrl,
        ),
      );
    } catch (e) {
      debugPrint('Vérification de mise à jour impossible : $e');
      return const AppUpdateCheckResult(error: 'Vérification impossible. Vérifiez votre connexion.');
    }
  }

  /// Télécharge l'APK puis ouvre l'installeur Android.
  /// Le flux émet la progression (0-100) via [OtaEvent.value].
  Stream<OtaEvent> downloadAndInstall(AppUpdateInfo info) {
    return OtaUpdate().execute(info.apkUrl, destinationFilename: 'invyra-${info.versionCode}.apk');
  }

  /// `Platform.version` se termine par `on "android_arm64"`, `"android_arm"` ou `"android_x64"`.
  String _deviceAbi() {
    final v = Platform.version;
    if (v.contains('android_arm64')) return 'arm64-v8a';
    if (v.contains('android_x64')) return 'x86_64';
    if (v.contains('android_arm')) return 'armeabi-v7a';
    return 'arm64-v8a';
  }
}
