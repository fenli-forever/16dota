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
          title: const Text('天梯',
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
            final result = p.result;
            return CustomScrollView(
              slivers: [
                // Season selector
                if (p.seasons.isNotEmpty)
                  SliverToBoxAdapter(child: _SeasonSelector(provider: p)),

                // Personal stats card
                if (result != null)
                  SliverToBoxAdapter(
                    child: _PersonalStatsCard(result: result),
                  ),

                // Global list (if API returns one)
                if (result != null && result.entries.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('排行榜',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final selfId = ctx.read<AuthProvider>().api.userId;
                          return _EntryCard(
                            entry: result.entries[i],
                            isSelf: result.entries[i].userId == selfId,
                          );
                        },
                        childCount: result.entries.length,
                      ),
                    ),
                  ),
                ],

                // No list but has personal stats — just end padding
                if (result != null && result.entries.isEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

// ── 个人段位卡片 ──────────────────────────────────────────────────────────

class _PersonalStatsCard extends StatelessWidget {
  final LeaderboardResult result;
  const _PersonalStatsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final hasStats = result.hasPersonalStats;
    final rankColor = _tierColor(result.rankName);
    final winPct = result.totalCount > 0
        ? (result.winRate * 100).toStringAsFixed(1)
        : (result.winCount + result.loseCount > 0
            ? (result.winCount / (result.winCount + result.loseCount) * 100)
                .toStringAsFixed(1)
            : '0.0');
    final total = result.totalCount > 0
        ? result.totalCount
        : result.winCount + result.loseCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: hasStats
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.military_tech,
                        color: Color(0xFFE8A020), size: 18),
                    const SizedBox(width: 6),
                    const Text('我的天梯',
                        style: TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 12)),
                    const Spacer(),
                    if (result.myRank > 0)
                      Text('#${result.myRank}',
                          style: const TextStyle(
                              color: Color(0xFFE8A020),
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.rankName.isNotEmpty ? result.rankName : '未定段',
                          style: TextStyle(
                              color: rankColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${result.rankPoints.toStringAsFixed(0)} 分',
                          style: const TextStyle(
                              color: Color(0xFF8B949E), fontSize: 13),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${result.mmr.toStringAsFixed(0)} MMR',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$winPct% 胜率',
                          style: TextStyle(
                              color: result.winRate >= 0.5
                                  ? const Color(0xFF2EA043)
                                  : const Color(0xFF8B949E),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatPill('${result.winCount}胜', const Color(0xFF2EA043)),
                    const SizedBox(width: 8),
                    _StatPill('${result.loseCount}负', const Color(0xFFDA3633)),
                    const SizedBox(width: 8),
                    _StatPill('共${total}场', const Color(0xFF484F58)),
                  ],
                ),
              ],
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('本赛季暂无天梯数据',
                    style: TextStyle(color: Color(0xFF8B949E), fontSize: 14)),
              ),
            ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

// ── 排行榜条目 ────────────────────────────────────────────────────────────

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
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF30363D),
            backgroundImage: entry.avatar.isNotEmpty
                ? NetworkImage(entry.avatar)
                : null,
            child: entry.avatar.isEmpty
                ? const Icon(Icons.person, size: 18, color: Color(0xFF8B949E))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.nickname.isEmpty ? '玩家' : entry.nickname,
                    style: TextStyle(
                      color: isSelf ? const Color(0xFFE8A020) : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(entry.rankName,
                    style: TextStyle(
                        color: _tierColor(entry.rankName), fontSize: 11)),
              ],
            ),
          ),
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
    final labels = ['🥇', '🥈', '🥉'];
    return Text(labels[rank - 1], style: const TextStyle(fontSize: 20));
  }
}

Color _tierColor(String rankName) {
  if (rankName.contains('永恒') || rankName.contains('超凡')) return const Color(0xFFE74C3C);
  if (rankName.contains('神话') || rankName.contains('传奇')) return const Color(0xFF9B59B6);
  if (rankName.contains('宗师') || rankName.contains('大师')) return const Color(0xFFE8A020);
  if (rankName.contains('精英') || rankName.contains('黄金')) return const Color(0xFFFFD700);
  if (rankName.contains('白银') || rankName.contains('铂金')) return const Color(0xFF87CEEB);
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
        const Icon(Icons.error_outline, color: Color(0xFF8B949E), size: 48),
        const SizedBox(height: 8),
        Text(error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8B949E))),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('重试')),
      ],
    ),
  );
}
