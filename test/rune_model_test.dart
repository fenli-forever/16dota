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

  test('level 1 dotamd runes use pc rune images instead of generic assets', () {
    final rune = kLevel1Runes.firstWhere((r) => r.icon == 'dotamd_1');
    expect(rune.name, '大力');
    expect(rune.assetPath, '');
    expect(
      rune.imageUrl,
      'https://img.16dota.com.cn/resources/images/dota-runes/'
      '%E7%AC%A6%E6%96%87_%E5%A4%A7%E5%8A%9B.jpg',
    );
  });

  test('rune lookup normalizes colored and prefixed names', () {
    final rune = RuneInfo.lookupLoose('|cffffcc001级符文：符文_大力|r', level: 1);
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

  test('player score fills 16dota hero image from settlement hero name', () {
    final score = PlayerScore.fromJson({
      'user_id': '1',
      'name': 'moes',
      'hero': '变体精灵',
    });

    expect(score.heroName, '变体精灵');
    expect(
      score.heroImage,
      'https://img.16dota.com.cn/resources/images/dota-heroes/'
      '%E5%8F%98%E4%BD%93%E7%B2%BE%E7%81%B5.jpg',
    );
  });

  test('player score maps settlement rune names to pc rune images', () {
    final score = PlayerScore.fromJson({
      'user_id': '1',
      'runes': [
        {'name': '符文_猴子猴孙', 'level': 3},
        {'name': '符文_万能狙击', 'level': 1},
      ],
    });

    expect(score.runes.map((r) => r.name), ['猴子猴孙', '万能狙击']);
    expect(
      score.runes.first.enrichedImageUrl,
      'https://img.16dota.com.cn/resources/images/dota-runes/'
      '%E7%AC%A6%E6%96%87_%E7%8C%B4%E5%AD%90%E7%8C%B4%E5%AD%99.jpg',
    );
    expect(score.runes.first.assetPath, 'assets/runes/fw/fw_59.png');
    expect(score.runes.last.assetPath, '');
  });

  test('player score fills 16dota item images from settlement item names', () {
    final score = PlayerScore.fromJson({
      'user_id': '1',
      'inventory': [
        {'name': '魔杖', 'stack': null},
        {'name': '净魂之刃-等级2', 'stack': null},
      ],
    });

    expect(score.items, ['魔杖', '净魂之刃-等级2']);
    expect(score.itemImages, [
      'https://img.16dota.com.cn/resources/images/dota-equips/'
          '%E9%AD%94%E6%9D%96.jpg',
      'https://img.16dota.com.cn/resources/images/dota-equips/'
          '%E5%87%80%E9%AD%82%E4%B9%8B%E5%88%83-%E7%AD%89%E7%BA%A72.jpg',
    ]);
  });
}
