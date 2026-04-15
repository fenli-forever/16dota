import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../models/leaderboard.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late LeaderboardProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = LeaderboardProvider(context.read<AuthProvider>().api);
    _provider.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          backgroundColor: const Color(0xFF161B22),
          elevation: 0,
          title: const Text('天梯榜',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            Consumer<LeaderboardProvider>(
              builder: (_, p, __) => IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)),
                onPressed: p.loading ? null : p.refresh,
              ),
            ),
          ],
        ),
        body: Consumer<LeaderboardProvider>(
          builder: (_, p, __) {
            if (p.loading && p.result == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE8A020)),
              );
            }
            if (p.error.isNotEmpty && p.result == null) {
              return _ErrorView(error: p.error, onRetry: p.init);
            }
            return Column(
              children: [
                if (p.seasons.isNotEmpty) _SeasonSelector(provider: p),
                if (p.result != null && p.result!.myRank > 0)
                  _MyRankBanner(rank: p.result!.myRank),
                Expanded(child: _LeaderboardList(provider: p)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── 赛季选择器 ────────────────────────────────────────────────────────────

class _SeasonSelector extends StatelessWidget {
  final LeaderboardProvider provider;
  const _SeasonSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('赛季：',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: provider.seasons.map((s) {
                  final selected = provider.selected?.activityId == s.activityId;
                  return GestureDetector(
                    onTap: () => provider.selectSeason(s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE8A020).withValues(alpha: 0.2)
                            : const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFE8A020)
                              : const Color(0xFF30363D),
                        ),
                      ),
                      child: Text(s.name,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFFE8A020)
                                : const Color(0xFF8B949E),
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 我的排名条 ────────────────────────────────────────────────────────────

class _MyRankBanner extends StatelessWidget {
  final int rank;
  const _MyRankBanner({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8A020).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFE8A020).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events,
              color: Color(0xFFE8A020), size: 18),
          const SizedBox(width: 8),
          const Text('我的排名：',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
          Text('#$rank',
              style: const TextStyle(
                  color: Color(0xFFE8A020),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── 排行榜列表 ────────────────────────────────────────────────────────────

class _LeaderboardList extends StatelessWidget {
  final LeaderboardProvider provider;
  const _LeaderboardList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final entries = provider.result?.entries ?? [];
    if (entries.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Color(0xFF8B949E))),
      );
    }
    final selfId = context.read<AuthProvider>().api.userId;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      itemCount: entries.length,
      itemBuilder: (_, i) => _EntryCard(
        entry: entries[i],
        isSelf: entries[i].userId == selfId,
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isSelf;
  const _EntryCard({required this.entry, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor(entry.rank);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelf
            ? const Color(0xFFE8A020).withValues(alpha: 0.08)
            : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelf
              ? const Color(0xFFE8A020).withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // 名次
          SizedBox(
            width: 36,
            child: entry.rank <= 3
                ? _MedalIcon(entry.rank)
                : Text('#${entry.rank}',
                    style: TextStyle(
                        color: rankColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),

          // 头像
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF30363D),
            backgroundImage: entry.avatar.isNotEmpty
                ? NetworkImage(entry.avatar)
                : null,
            child: entry.avatar.isEmpty
                ? const Icon(Icons.person,
                    size: 18, color: Color(0xFF8B949E))
                : null,
          ),
          const SizedBox(width: 10),

          // 昵称 + 段位
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.nickname.isEmpty ? '玩家' : entry.nickname,
                    style: TextStyle(
                      color: isSelf
                          ? const Color(0xFFE8A020)
                          : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(entry.rankName,
                    style: TextStyle(
                        color: _tierColor(entry.rankName),
                        fontSize: 11)),
              ],
            ),
          ),

          // MMR + 胜率
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.mmr.toStringAsFixed(0)} MMR',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                  '${entry.winCount}胜${entry.loseCount}负 '
                  '${(entry.winRate * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Color(0xFF8B949E), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return const Color(0xFF8B949E);
  }
}

class _MedalIcon extends StatelessWidget {
  final int rank;
  const _MedalIcon(this.rank);

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final labels = ['🥇', '🥈', '🥉'];
    return Text(labels[rank - 1],
        style: TextStyle(
            fontSize: 20,
            color: colors[rank - 1]));
  }
}

Color _tierColor(String rankName) {
  final n = rankName;
  if (n.contains('永恒') || n.contains('超凡')) return const Color(0xFFE74C3C);
  if (n.contains('神话') || n.contains('传奇')) return const Color(0xFF9B59B6);
  if (n.contains('宗师') || n.contains('大师')) return const Color(0xFFE8A020);
  if (n.contains('精英') || n.contains('黄金')) return const Color(0xFFFFD700);
  if (n.contains('白银') || n.contains('铂金')) return const Color(0xFF87CEEB);
  return const Color(0xFF8B949E);
}

// ── 错误视图 ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline,
            color: Color(0xFF8B949E), size: 48),
        const SizedBox(height: 8),
        Text(error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8B949E))),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: onRetry, child: const Text('重试')),
      ],
    ),
  );
}
