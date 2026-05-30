import 'package:dota16/data/rune_data.dart';
import 'package:dota16/models/match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MD initial items use the first 16 FW icons', () {
    expect(kMdRuneItems.length, 16);
    for (var i = 0; i < kMdRuneItems.length; i++) {
      expect(kMdRuneItems[i].icon, 'fw_${i + 1}');
      expect(kMdRuneItems[i].assetPath, 'assets/runes/fw/fw_${i + 1}.png');
    }
  });

  test('level 1 dotamd runes use generic rune icon instead of FW items', () {
    final rune = kLevel1Runes.firstWhere((r) => r.icon == 'dotamd_1');
    expect(rune.name, '大力');
    expect(rune.assetPath, 'assets/runes/ui/fw.png');
  });

  test('rune lookup normalizes colored and prefixed names', () {
    final rune = RuneInfo.lookupLoose('|cffffcc001级符文：大力|r', level: 1);
    expect(rune?.name, '大力');
  });

  test('player score extracts runes from service-like payloads', () {
    final score = PlayerScore.fromJson({
      'user_id': '1',
      'services': [
        {'service_name': '1级符文：大力', 'level': '1', 'icon': 'dotamd_1'},
        {
          'service_name': '符文服务',
          'data': [
            {'name': '射程专精', 'level': 2, 'icon': 'fw_1'},
          ],
        },
        {'name': '攻击之弩', 'level': 1},
        {'serviceName': '不是符文服务'},
      ],
    });

    expect(score.runes.map((r) => r.name), containsAll(['大力', '射程专精', '攻击之弩']));
    expect(
      score.runes.firstWhere((r) => r.name == '攻击之弩').assetPath,
      'assets/runes/fw/fw_1.png',
    );
    expect(score.runes.map((r) => r.name), isNot(contains('不是符文服务')));
  });

  test('player score extracts hero and item images from pc-like payloads', () {
    final score = PlayerScore.fromJson({
      'user_id': '1',
      'user': {'nick_name': 'moes', 'pic': '//img.16dota.com.cn/avatar.png'},
      'hero': {'name': '山岭巨人', 'icon_url': '/hero/tiny.png'},
      'items': [
        {'itemName': '跳刀', 'icon': '/item/blink.png'},
        {'name': '魔杖', 'imageUrl': 'https://img.16dota.com.cn/item/wand.png'},
      ],
    });

    expect(score.nickname, 'moes');
    expect(score.avatar, 'https://img.16dota.com.cn/avatar.png');
    expect(score.heroName, '山岭巨人');
    expect(score.heroImage, 'https://img.16dota.com.cn/hero/tiny.png');
    expect(score.items, ['跳刀', '魔杖']);
    expect(score.itemImages.first, 'https://img.16dota.com.cn/item/blink.png');
  });
}
