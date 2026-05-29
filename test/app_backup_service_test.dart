import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dota16/providers/friends_provider.dart';
import 'package:dota16/services/app_backup_service.dart';
import 'package:dota16/services/external_ai_service.dart';

void main() {
  test('exports and imports friends with external AI config', () async {
    SharedPreferences.setMockInitialValues({
      FriendsProvider.storageKey: jsonEncode([
        {
          'userId': '10001',
          'nickname': 'player',
          'avatar': 'avatar.png',
          'rankName': '冠绝',
        },
      ]),
      ExternalAiConfig.keyBaseUrl: 'https://api.example.com',
      ExternalAiConfig.keyApiKey: 'secret',
      ExternalAiConfig.keyModel: 'model-a',
    });

    final backup = await AppBackupService.exportText();

    SharedPreferences.setMockInitialValues({});
    final result = await AppBackupService.importText(backup);
    final prefs = await SharedPreferences.getInstance();

    expect(result.friendCount, 1);
    expect(result.hasExternalAiConfig, isTrue);
    expect(
      prefs.getString(ExternalAiConfig.keyBaseUrl),
      'https://api.example.com',
    );
    expect(prefs.getString(ExternalAiConfig.keyApiKey), 'secret');
    expect(prefs.getString(ExternalAiConfig.keyModel), 'model-a');

    final friends =
        jsonDecode(prefs.getString(FriendsProvider.storageKey)!) as List;
    expect(friends.single['userId'], '10001');
    expect(friends.single['nickname'], 'player');
  });
}
