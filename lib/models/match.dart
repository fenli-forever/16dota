import '../data/rune_data.dart';

// ── 战绩列表条目（来自 match_history）────────────────────────────────────
class MatchRecord {
  final String gameId;
  final String matchType; // MD / RD 等
  final String mapId;
  final DateTime startTime;
  final DateTime endTime;
  final int wonTeam; // 0 or 1
  final int myTeam; // 0 or 1
  final bool isInvalid;
  final String remark; // 游戏备注（MVP 英雄名）

  const MatchRecord({
    required this.gameId,
    required this.matchType,
    required this.mapId,
    required this.startTime,
    required this.endTime,
    required this.wonTeam,
    required this.myTeam,
    required this.isInvalid,
    required this.remark,
  });

  bool get isWin => myTeam == wonTeam;

  Duration get duration => endTime.difference(startTime);

  String get durationStr {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory MatchRecord.fromJson(
    Map<String, dynamic> j, {
    String selfUserId = '',
  }) {
    final players = (j['players'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final me = players.firstWhere(
      (p) => p['user_id'] == selfUserId,
      orElse: () => players.isNotEmpty ? players.first : {},
    );

    DateTime parseTime(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val)?.toLocal() ?? DateTime.now();
      }
      if (val is num) {
        return DateTime.fromMillisecondsSinceEpoch(val.toInt() * 1000);
      }
      return DateTime.now();
    }

    return MatchRecord(
      gameId: j['game_id']?.toString() ?? '',
      matchType: j['match_type']?.toString() ?? '',
      mapId: j['map_id']?.toString() ?? '',
      startTime: parseTime(j['start_time']),
      endTime: parseTime(j['end_time']),
      wonTeam: (j['won_team'] as num?)?.toInt() ?? -1,
      myTeam: (me['team'] as num?)?.toInt() ?? -1,
      isInvalid: j['is_invalid'] == true,
      remark: j['remark']?.toString() ?? '',
    );
  }
}

// ── 结算详情（来自 settlement）───────────────────────────────────────────
class MatchDetail {
  final String gameId;
  final String duration; // "15:42"
  final String mode;
  final String winTeamName; // "近卫" / "天灾"
  final List<PlayerScore> players;

  const MatchDetail({
    required this.gameId,
    required this.duration,
    required this.mode,
    required this.winTeamName,
    required this.players,
  });

  factory MatchDetail.fromJson(Map<String, dynamic> j) {
    // 兼容多种嵌套结构：scores.global / 顶层字段
    final scores = j['scores'] as Map<String, dynamic>? ?? {};
    final global = scores['global'] as Map<String, dynamic>? ?? {};

    // 玩家列表：scores.players > players > 顶层列表
    final rawList =
        ((scores['players'] ?? j['players']) as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    // 时长：global.current_duration > 顶层 duration / game_duration
    final duration =
        global['current_duration']?.toString() ??
        j['duration']?.toString() ??
        j['game_duration']?.toString() ??
        '';

    // 模式
    final mode = global['mode']?.toString() ?? j['mode']?.toString() ?? '';

    // 胜利队伍名
    final winTeamName =
        global['win']?.toString() ??
        j['win_team']?.toString() ??
        j['win']?.toString() ??
        '';

    return MatchDetail(
      gameId: j['game_id']?.toString() ?? '',
      duration: duration,
      mode: mode,
      winTeamName: winTeamName,
      players: rawList.map(PlayerScore.fromJson).toList(),
    );
  }

  PlayerScore? playerById(String userId) =>
      players.where((p) => p.userId == userId).firstOrNull;
}

class PlayerScore {
  final String userId;
  final String nickname;
  final String avatar;
  final String heroName;
  final String heroImage;
  final String teamName;
  final int kills;
  final int deaths;
  final int assists;
  final double kda;
  final int level;
  final int gold;
  final int heroDamage;
  final int heroHealing;
  final int towerDamage;
  final int lastHits;
  final int denies;
  final double incRankPoints;
  final double incMmr;
  final double rankPoints;
  final String rankName;
  final double mmr;
  final double participationRate;
  final bool isMostKills;
  final double mvpScore;
  final List<String> items; // inventory names (for tooltip)
  final List<String> itemImages; // inventory image URLs
  final List<RuneRecord> runes;

  const PlayerScore({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.heroName,
    required this.heroImage,
    required this.teamName,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.kda,
    required this.level,
    required this.gold,
    required this.heroDamage,
    required this.heroHealing,
    required this.towerDamage,
    required this.lastHits,
    required this.denies,
    required this.incRankPoints,
    required this.incMmr,
    required this.rankPoints,
    required this.rankName,
    required this.mmr,
    required this.participationRate,
    required this.isMostKills,
    required this.mvpScore,
    required this.items,
    required this.itemImages,
    required this.runes,
  });

  String get kdaStr {
    if (deaths == 0) return '${kills + assists}/0/$assists';
    return ((kills + assists) / deaths).toStringAsFixed(2);
  }

  factory PlayerScore.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    final heroMap = _asStringMap(j['hero']);
    final inventory = _extractInventory(j);
    final runes = _extractRunes(j);
    // is_mvp 可能是 bool 或 Map{score:...}
    final mvpRaw = j['is_mvp'];
    final mvp = mvpRaw is Map
        ? mvpRaw.cast<String, dynamic>()
        : <String, dynamic>{};
    final explicitHeroName = _firstStringFromMaps(
      [j],
      const ['hero_name', 'heroName'],
    );
    final mappedHeroName = _firstStringFromMaps(
      [heroMap],
      const ['name', 'title', 'label'],
    );
    final heroName = explicitHeroName.isNotEmpty
        ? explicitHeroName
        : mappedHeroName.isNotEmpty
        ? mappedHeroName
        : j['hero'] is String
        ? j['hero'].toString()
        : '';

    final explicitHeroImage = _imageUrl(
      _firstStringFromMaps(
        [j, heroMap],
        const [
          'hero_image',
          'heroImage',
          'hero_icon',
          'heroIcon',
          'hero_avatar',
          'heroAvatar',
          'hero_pic',
          'heroPic',
          'hero_img',
          'heroImg',
          'image_url',
          'imageUrl',
          'icon_url',
          'iconUrl',
          'avatar',
          'pic',
          'img_url',
          'imgUrl',
          'img',
          'url',
        ],
      ),
    );
    final itemNames = inventory
        .map(
          (e) => _firstStringFromMaps(
            [e],
            const ['name', 'item_name', 'itemName', 'title', 'label'],
          ),
        )
        .toList();
    final itemImages = <String>[];
    for (var i = 0; i < inventory.length; i++) {
      final explicitItemImage = _imageUrl(
        _firstStringFromMaps(
          [inventory[i]],
          const [
            'image_url',
            'imageUrl',
            'icon',
            'icon_url',
            'iconUrl',
            'img_url',
            'imgUrl',
            'img',
            'pic',
            'url',
            'path',
          ],
        ),
      );
      itemImages.add(
        explicitItemImage.isNotEmpty
            ? explicitItemImage
            : _dotaImageUrl(itemNames[i], 'equips'),
      );
    }

    return PlayerScore(
      userId: j['user_id']?.toString() ?? user['user_id']?.toString() ?? '',
      nickname: user['nick_name']?.toString() ?? j['name']?.toString() ?? '',
      avatar: _imageUrl(
        _firstStringFromMaps(
          [user, j],
          const [
            'pic',
            'avatar',
            'avatar_url',
            'avatarUrl',
            'head_img',
            'headImg',
          ],
        ),
      ),
      heroName: heroName,
      heroImage: explicitHeroImage.isNotEmpty
          ? explicitHeroImage
          : _dotaImageUrl(heroName, 'heroes'),
      teamName: j['team']?.toString() ?? '',
      kills: (j['kills'] as num?)?.toInt() ?? 0,
      deaths: (j['deaths'] as num?)?.toInt() ?? 0,
      assists: (j['assists'] as num?)?.toInt() ?? 0,
      kda: (j['kda'] as num?)?.toDouble() ?? 0,
      level: (j['level'] as num?)?.toInt() ?? 0,
      gold: (j['gold'] as num?)?.toInt() ?? 0,
      heroDamage: (j['hero_damage'] as num?)?.toInt() ?? 0,
      heroHealing: (j['hero_healing'] as num?)?.toInt() ?? 0,
      towerDamage: (j['tower_damage'] as num?)?.toInt() ?? 0,
      lastHits: (j['last_hits'] as num?)?.toInt() ?? 0,
      denies: (j['denies'] as num?)?.toInt() ?? 0,
      incRankPoints: (j['inc_rank_points'] as num?)?.toDouble() ?? 0,
      incMmr: (j['inc_mmr'] as num?)?.toDouble() ?? 0,
      rankPoints: (j['rank_points'] as num?)?.toDouble() ?? 0,
      rankName: j['rank_name']?.toString() ?? '',
      mmr: (j['mmr'] as num?)?.toDouble() ?? 0,
      participationRate: (j['participation_rate'] as num?)?.toDouble() ?? 0,
      isMostKills: j['is_most_kills'] == true || mvp['is_most_kills'] == true,
      mvpScore: (mvp['score'] as num?)?.toDouble() ?? 0,
      items: itemNames,
      itemImages: itemImages,
      runes: runes,
    );
  }

  static Map<String, dynamic> _asStringMap(Object? value) {
    if (value is! Map) return {};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static List<Map<String, dynamic>> _extractInventory(Map<String, dynamic> j) {
    const keys = [
      'inventory',
      'items',
      'item_list',
      'itemList',
      'equips',
      'equipment',
      'equipments',
    ];
    for (final key in keys) {
      final value = j[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
            .toList();
      }
    }
    return const [];
  }

  static String _firstStringFromMaps(
    List<Map<String, dynamic>> maps,
    List<String> keys,
  ) {
    for (final map in maps) {
      if (map.isEmpty) continue;
      for (final key in keys) {
        final value = map[key];
        if (value is Map) continue;
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty && text != 'null') return text;
      }
    }
    return '';
  }

  static String _imageUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';
    if (text.startsWith(RegExp(r'https?://'))) return text;
    if (text.startsWith('//')) return 'https:$text';
    if (text.startsWith('/')) return 'https://img.16dota.com.cn$text';
    return text;
  }

  static String _dotaImageUrl(String name, String type) {
    final text = name.trim();
    if (text.isEmpty) return '';
    return 'https://img.16dota.com.cn/resources/images/dota-$type/'
        '${Uri.encodeComponent(text)}.jpg';
  }

  static List<RuneRecord> _extractRunes(Map<String, dynamic> playerJson) {
    final records = <RuneRecord>[];
    const keys = [
      'runes',
      'rune',
      'rune_list',
      'runeList',
      'md_runes',
      'mdRunes',
      'md_rune',
      'mdRune',
      'magic_runes',
      'magicRunes',
      'services',
      'service',
    ];

    for (final key in keys) {
      _collectRuneRecords(playerJson[key], records);
    }

    final seen = <String>{};
    return records.where((record) {
      final name = RuneInfo.normalizeName(record.name);
      if (name.isEmpty) return false;
      final key = '$name@${record.level}@${record.imageUrl}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  static void _collectRuneRecords(Object? value, List<RuneRecord> output) {
    if (value == null) return;
    if (value is String) {
      final record = RuneRecord.fromDynamic(value);
      if (record != null) output.add(record);
      return;
    }
    if (value is List) {
      for (final item in value) {
        _collectRuneRecords(item, output);
      }
      return;
    }
    if (value is Map) {
      final map = value.map((key, value) => MapEntry(key.toString(), value));
      final record = RuneRecord.fromDynamic(map);
      if (record != null) {
        output.add(record);
      }

      for (final nestedKey in [
        'runes',
        'rune',
        'items',
        'list',
        'data',
        'value',
        'services',
      ]) {
        _collectRuneRecords(map[nestedKey], output);
      }
    }
  }
}

class RuneRecord {
  final String name;
  final int level;
  final String imageUrl;
  final String description;
  const RuneRecord({
    required this.name,
    required this.level,
    this.imageUrl = '',
    this.description = '',
  });

  RuneInfo? get _staticInfo =>
      RuneInfo.lookupLoose(name, level: level > 0 ? level : null);

  String get enrichedDescription =>
      description.isNotEmpty ? description : _staticInfo?.description ?? '';

  String get enrichedImageUrl =>
      imageUrl.isNotEmpty && imageUrl.startsWith(RegExp(r'https?://'))
      ? imageUrl
      : _staticInfo?.imageUrl ?? '';

  String get assetPath =>
      _assetPathFromIcon(imageUrl) ?? _staticInfo?.assetPath ?? '';

  bool get hasStaticInfo => _staticInfo != null;

  static String? _assetPathFromIcon(String icon) {
    final lower = icon.toLowerCase();
    if (lower.startsWith(RegExp(r'https?://'))) return null;
    final fwMatch = RegExp(r'fw[_\\/-]?(\d+)').firstMatch(lower);
    if (fwMatch != null) {
      return 'assets/runes/fw/fw_${fwMatch.group(1)}.png';
    }
    final dotamdMatch = RegExp(r'dotamd[_\\/-]?(\d+)').firstMatch(lower);
    if (dotamdMatch != null) {
      return 'assets/runes/ui/fw.png';
    }
    if (lower.contains('rune')) {
      return 'assets/runes/ui/fw.png';
    }
    return null;
  }

  factory RuneRecord.fromJson(Map<String, dynamic> j) =>
      fromDynamic(j) ?? const RuneRecord(name: '', level: 0);

  static RuneRecord? fromDynamic(Object? value) {
    if (value is String) {
      final name = value.trim();
      if (name.isEmpty) return null;
      final info = RuneInfo.lookupLoose(name);
      if (info == null) return null;
      return RuneRecord(
        name: info.name,
        level: info.level,
        imageUrl: info.imageUrl,
        description: info.description,
      );
    }

    if (value is! Map) return null;
    final j = value.map((key, value) => MapEntry(key.toString(), value));
    final name = _firstString(j, const [
      'name',
      'rune_name',
      'runeName',
      'title',
      'label',
      'service_name',
      'serviceName',
    ]);
    final imageUrl = _firstString(j, const [
      'image_url',
      'imageUrl',
      'icon',
      'icon_url',
      'iconUrl',
      'img_url',
      'imgUrl',
      'img',
      'pic',
    ]);
    final description = _firstString(j, const [
      'description',
      'desc',
      'effect',
      'detail',
    ]);
    final level = _firstInt(j, const [
      'level',
      'lv',
      'rune_level',
      'runeLevel',
    ]);
    final info = RuneInfo.lookupLoose(name, level: level > 0 ? level : null);

    if (name.isEmpty && info == null) return null;
    if (info == null &&
        level <= 0 &&
        description.isEmpty &&
        !_looksLikeRuneImage(imageUrl)) {
      return null;
    }
    return RuneRecord(
      name: info?.name ?? name,
      level: level > 0 ? level : info?.level ?? 0,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : info?.imageUrl ?? '',
      description: description.isNotEmpty
          ? description
          : info?.description ?? '',
    );
  }

  static String _firstString(Map<String, dynamic> j, List<String> keys) {
    for (final key in keys) {
      final value = j[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static int _firstInt(Map<String, dynamic> j, List<String> keys) {
    for (final key in keys) {
      final value = j[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static bool _looksLikeRuneImage(String value) {
    final lower = value.toLowerCase();
    return lower.contains('rune') ||
        lower.contains('dotamd') ||
        RegExp(r'fw[_\\/-]?\d+').hasMatch(lower);
  }
}

// ── 玩家简介 ──────────────────────────────────────────────────────────────
class PlayerProfile {
  final int playerId;
  final String userId;
  final String nickname;
  final String avatar;
  final String rankName;
  final double rankPoints;
  final double mmr;
  final int winCount;
  final int loseCount;
  final double winRate;

  const PlayerProfile({
    required this.playerId,
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.rankName,
    required this.rankPoints,
    required this.mmr,
    required this.winCount,
    required this.loseCount,
    required this.winRate,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> j) {
    final pi = j['player_info'] as Map<String, dynamic>? ?? j;
    return PlayerProfile(
      playerId: (pi['id'] as num?)?.toInt() ?? 0,
      // extid = mall4j userId, used for match history URL
      // check both inside player_info and at top level of data
      userId:
          pi['extid']?.toString() ??
          j['extid']?.toString() ??
          j['user_id']?.toString() ??
          pi['user_id']?.toString() ??
          pi['userId']?.toString() ??
          '',
      nickname:
          pi['name']?.toString() ??
          pi['nickname']?.toString() ??
          pi['nick_name']?.toString() ??
          pi['nick']?.toString() ??
          '',
      avatar: pi['avatar']?.toString() ?? '',
      rankName: pi['rank_name']?.toString() ?? '',
      rankPoints: (pi['rank_points'] as num?)?.toDouble() ?? 0,
      mmr: (pi['mmr'] as num?)?.toDouble() ?? 0,
      winCount: (pi['win_count'] as num?)?.toInt() ?? 0,
      loseCount: (pi['lose_count'] as num?)?.toInt() ?? 0,
      winRate: (pi['win_rate'] as num?)?.toDouble() ?? 0,
    );
  }

  /// 合并三个接口数据构造 Profile
  /// rustData  = rustwar /api/user/userinfo 的 data（含 player_info）
  /// mallData  = mall4j  /p/user/userInfo   的 data（含 nickName/pic）
  /// ladderData= leaderboard record         的 data（含 rank_name/win_count...）
  factory PlayerProfile.fromMerged(
    Map<String, dynamic> rustData,
    Map<String, dynamic> mallData,
    Map<String, dynamic> ladderData,
  ) {
    final pi = rustData['player_info'] as Map<String, dynamic>? ?? rustData;

    // 昵称：mall4j nickName > rustwar name
    final nickname =
        mallData['nickName']?.toString() ??
        mallData['nick_name']?.toString() ??
        pi['name']?.toString() ??
        '';

    // 头像：mall4j pic > rustwar avatar
    final avatar =
        mallData['pic']?.toString() ?? pi['avatar']?.toString() ?? '';

    // userId：rustwar extId > mall4j userId
    final userId =
        pi['extid']?.toString() ??
        mallData['userId']?.toString() ??
        pi['user_id']?.toString() ??
        '';

    final winRate = (ladderData['win_rate'] as num?)?.toDouble() ?? 0;

    return PlayerProfile(
      playerId: (pi['id'] as num?)?.toInt() ?? 0,
      userId: userId,
      nickname: nickname,
      avatar: avatar,
      rankName: ladderData['rank_name']?.toString() ?? '',
      rankPoints: (ladderData['rank_points'] as num?)?.toDouble() ?? 0,
      mmr:
          (ladderData['rating'] as num?)?.toDouble() ??
          (ladderData['mmr'] as num?)?.toDouble() ??
          0,
      winCount: (ladderData['win_count'] as num?)?.toInt() ?? 0,
      loseCount:
          (ladderData['fail_count'] as num?)?.toInt() ??
          (ladderData['lose_count'] as num?)?.toInt() ??
          0,
      winRate: winRate > 1 ? winRate / 100 : winRate,
    );
  }
}
