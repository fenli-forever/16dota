class Season {
  final int activityId;
  final String name;
  final bool isCurrent;

  const Season({
    required this.activityId,
    required this.name,
    required this.isCurrent,
  });

  factory Season.fromJson(Map<String, dynamic> j, {bool isCurrent = false}) =>
      Season(
        activityId: (j['activity_id'] as num?)?.toInt() ??
            (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? j['season_name']?.toString() ?? '未知赛季',
        isCurrent: isCurrent,
      );
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String nickname;
  final String avatar;
  final double mmr;
  final String rankName;
  final double rankPoints;
  final int winCount;
  final int loseCount;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.mmr,
    required this.rankName,
    required this.rankPoints,
    required this.winCount,
    required this.loseCount,
  });

  int get totalGames => winCount + loseCount;
  double get winRate =>
      totalGames == 0 ? 0 : winCount / totalGames;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    return LeaderboardEntry(
      rank:       (j['rank'] as num?)?.toInt() ?? 0,
      userId:     j['user_id']?.toString() ?? user['user_id']?.toString() ?? '',
      nickname:   j['nickname']?.toString() ??
                  user['nick_name']?.toString() ??
                  user['nickname']?.toString() ?? '',
      avatar:     j['avatar']?.toString() ?? user['pic']?.toString() ?? '',
      mmr:        (j['mmr'] as num?)?.toDouble() ?? 0,
      rankName:   j['rank_name']?.toString() ?? '',
      rankPoints: (j['rank_points'] as num?)?.toDouble() ?? 0,
      winCount:   (j['win_count'] as num?)?.toInt() ?? 0,
      loseCount:  (j['lose_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardResult {
  final int myRank;
  final List<LeaderboardEntry> entries;

  const LeaderboardResult({required this.myRank, required this.entries});

  factory LeaderboardResult.fromJson(Map<String, dynamic> j) {
    final list = (j['list'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return LeaderboardResult(
      myRank:  (j['rank'] as num?)?.toInt() ?? 0,
      entries: list.map(LeaderboardEntry.fromJson).toList(),
    );
  }
}
