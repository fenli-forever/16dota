import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../providers/friends_provider.dart';
import 'external_ai_service.dart';

class AppBackupImportResult {
  final int friendCount;
  final bool hasExternalAiConfig;

  const AppBackupImportResult({
    required this.friendCount,
    required this.hasExternalAiConfig,
  });
}

class AppBackupService {
  static const _backupVersion = 1;

  static Future<String> exportText() async {
    final prefs = await SharedPreferences.getInstance();
    final friends = _decodeFriends(prefs.getString(FriendsProvider.storageKey));
    final config = await ExternalAiConfig.load();

    final payload = <String, dynamic>{
      'version': _backupVersion,
      'friends': friends,
      'external_ai': {
        'baseUrl': config.baseUrl,
        'apiKey': config.apiKey,
        'model': config.model,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Future<AppBackupImportResult> importText(String text) async {
    final decoded = jsonDecode(text.trim());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('备份内容格式不正确');
    }

    final friends = _normalizeFriends(decoded['friends']);
    final externalAi = _normalizeExternalAi(decoded['external_ai']);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(FriendsProvider.storageKey, jsonEncode(friends));
    if (externalAi != null) {
      await prefs.setString(ExternalAiConfig.keyBaseUrl, externalAi.baseUrl);
      await prefs.setString(ExternalAiConfig.keyApiKey, externalAi.apiKey);
      await prefs.setString(ExternalAiConfig.keyModel, externalAi.model);
    }

    return AppBackupImportResult(
      friendCount: friends.length,
      hasExternalAiConfig: externalAi?.isConfigured ?? false,
    );
  }

  static List<Map<String, dynamic>> _decodeFriends(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return _normalizeFriends(jsonDecode(raw));
    } catch (_) {
      return const [];
    }
  }

  static List<Map<String, dynamic>> _normalizeFriends(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .where((item) => (item['userId']?.toString() ?? '').isNotEmpty)
        .toList();
  }

  static ExternalAiConfig? _normalizeExternalAi(Object? value) {
    if (value is! Map) return null;
    return ExternalAiConfig(
      baseUrl: value['baseUrl']?.toString().trim() ?? '',
      apiKey: value['apiKey']?.toString().trim() ?? '',
      model: value['model']?.toString().trim() ?? '',
    );
  }
}
