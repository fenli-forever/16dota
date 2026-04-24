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

/// Global leaderboard list entry (when API returns a list of players).
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
  double get winRate => totalGames == 0 ? 0 : winCount / totalGames;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    return LeaderboardEntry(
      rank:       (j['rank'] as num?)?.toInt() ?? 0,
      userId:     j['user_id']?.toString() ?? user['user_id']?.toString() ?? '',
      nickname:   j['nickname']?.toString() ??
                  user['nick_name']?.toString() ??
                  user['nickname']?.toString() ?? '',
      avatar:     j['avatar']?.toString() ?? user['pic']?.toString() ?? '',
      // API may use 'rating' or 'mmr'
      mmr:        (j['mmr'] as num?)?.toDouble() ??
                  (j['rating'] as num?)?.toDouble() ?? 0,
      rankName:   j['rank_name']?.toString() ?? '',
      rankPoints: (j['rank_points'] as num?)?.toDouble() ?? 0,
      winCount:   (j['win_count'] as num?)?.toInt() ?? 0,
      // API may use 'fail_count' or 'lose_count'
      loseCount:  (j['lose_count'] as num?)?.toInt() ??
                  (j['fail_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The result returned by the leaderboard API.
/// The API always returns the current user's personal stats.
/// It may also return a list of top players under the 'list' key.
class LeaderboardResult {
  final int myRank;
  final String rankName;
  final double mmr;
  final double rankPoints;
  final int winCount;
  final int loseCount;
  final int totalCount;
  final double winRate;
  final List<LeaderboardEntry> entries;

  const LeaderboardResult({
    required this.myRank,
    required this.rankName,
    required this.mmr,
    required this.rankPoints,
    required this.winCount,
    required this.loseCount,
    required this.totalCount,
    required this.winRate,
    required this.entries,
  });

  bool get hasPersonalStats => winCount > 0 || loseCount > 0 || myRank > 0;

  factory LeaderboardResult.fromJson(Map<String, dynamic> j) {
    final rawList = j['list'] as List?;
    final entries = rawList
        ?.whereType<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromJson)
        .toList() ?? [];

    return LeaderboardResult(
      myRank:     (j['rank'] as num?)?.toInt() ?? 0,
      rankName:   j['rank_name']?.toString() ?? '',
      mmr:        (j['mmr'] as num?)?.toDouble() ??
                  (j['rating'] as num?)?.toDouble() ?? 0,
      rankPoints: (j['rank_points'] as num?)?.toDouble() ?? 0,
      winCount:   (j['win_count'] as num?)?.toInt() ?? 0,
      loseCount:  (j['lose_count'] as num?)?.toInt() ??
                  (j['fail_count'] as num?)?.toInt() ?? 0,
      totalCount: (j['total_count'] as num?)?.toInt() ?? 0,
      winRate:    (j['win_rate'] as num?)?.toDouble() ?? 0,
      entries:    entries,
    );
  }
}
