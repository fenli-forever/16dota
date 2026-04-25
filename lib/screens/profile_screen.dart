import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../models/match.dart';
import '../models/leaderboard.dart';

Color _tierColor(String n) {
  if (n.contains('永恒') || n.contains('超凡')) return const Color(0xFFE74C3C);
  if (n.contains('神话') || n.contains('传奇')) return const Color(0xFF9B59B6);
  if (n.contains('宗师') || n.contains('大师')) return const Color(0xFFE8A020);
  if (n.contains('精英') || n.contains('黄金')) return const Color(0xFFFFD700);
  if (n.contains('白银') || n.contains('铂金')) return const Color(0xFF87CEEB);
  return const Color(0xFF8B949E);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late LeaderboardProvider _ladder;

  @override
  void initState() {
    super.initState();
    _ladder = LeaderboardProvider(context.read<AuthProvider>().api);
    _ladder.init();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<AuthProvider>().refreshProfile(),
      _ladder.refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final profile = auth.profile;

    return ChangeNotifierProvider.value(
      value: _ladder,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          backgroundColor: const Color(0xFF161B22),
          elevation: 0,
          title: const Text('我的',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            Consumer<LeaderboardProvider>(
              builder: (_, lp, __) => IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)),
                tooltip: '刷新',
                onPressed: lp.loading ? null : _refresh,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF8B949E)),
              tooltip: '退出登录',
              onPressed: () => _confirmLogout(context, auth),
            ),
          ],
        ),
        body: profile == null
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE8A020)))
            : RefreshIndicator(
                color: const Color(0xFFE8A020),
                backgroundColor: const Color(0xFF161B22),
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _AvatarCard(profile: profile),
                    const SizedBox(height: 12),
                    const _LadderSection(),
                    if (kDebugMode && _isDataEmpty(profile)) ...[
                      const SizedBox(height: 12),
                      _DebugCard(auth: auth),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  bool _isDataEmpty(PlayerProfile p) =>
      p.rankName.isEmpty && p.mmr == 0 && p.winCount == 0;

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('退出登录',
            style: TextStyle(color: Colors.white)),
        content: const Text('确定要退出登录吗？',
            style: TextStyle(color: Color(0xFF8B949E))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消',
                style: TextStyle(color: Color(0xFF8B949E))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            child: const Text('退出',
                style: TextStyle(color: Color(0xFFDA3633))),
          ),
        ],
      ),
    );
  }
}

// ── 头像 + 基本信息 ────────────────────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  final PlayerProfile profile;
  const _AvatarCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: const Color(0xFF30363D),
            backgroundImage: profile.avatar.isNotEmpty
                ? NetworkImage(profile.avatar)
                : null,
            child: profile.avatar.isEmpty
                ? const Icon(Icons.person, size: 38, color: Color(0xFF8B949E))
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nickname.isEmpty ? 'Player' : profile.nickname,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('ID: ${profile.playerId}',
                    style: const TextStyle(
                        color: Color(0xFF8B949E), fontSize: 13)),
                if (profile.userId.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('UID: ${profile.userId}',
                      style: const TextStyle(
                          color: Color(0xFF484F58), fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 天梯区域（赛季选择 + 数据卡片）────────────────────────────────────────

class _LadderSection extends StatelessWidget {
  const _LadderSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardProvider>(
      builder: (_, lp, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 区域标题 + 赛季选择
            Row(
              children: [
                const Text('天梯',
                    style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
                const SizedBox(width: 12),
                if (lp.seasons.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: lp.seasons.map((s) {
                          final sel = lp.selected?.activityId == s.activityId;
                          return GestureDetector(
                            onTap: () => lp.selectSeason(s),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFFE8A020).withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sel
                                      ? const Color(0xFFE8A020)
                                      : const Color(0xFF30363D),
                                ),
                              ),
                              child: Text(s.name,
                                  style: TextStyle(
                                    color: sel
                                        ? const Color(0xFFE8A020)
                                        : const Color(0xFF8B949E),
                                    fontSize: 11,
                                    fontWeight: sel
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
            const SizedBox(height: 10),

            // 数据卡片
            if (lp.loading && lp.result == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFE8A020)),
                ),
              )
            else if (lp.error.isNotEmpty && lp.result == null)
              _LadderError(error: lp.error, onRetry: lp.init)
            else if (lp.result != null)
              _LadderCard(result: lp.result!),
          ],
        );
      },
    );
  }
}

class _LadderError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _LadderError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF161B22),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        const Icon(Icons.error_outline, color: Color(0xFF8B949E), size: 36),
        const SizedBox(height: 8),
        Text(error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('重试')),
      ],
    ),
  );
}

class _LadderCard extends StatelessWidget {
  final LeaderboardResult result;
  const _LadderCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final rankColor = _tierColor(result.rankName);
    final total = result.totalCount > 0
        ? result.totalCount
        : result.winCount + result.loseCount;
    final winPct = total > 0
        ? (result.winCount / total * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: result.hasPersonalStats
          ? Column(
              children: [
                // 段位名 + 排名
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      result.rankName.isNotEmpty ? result.rankName : '未定段',
                      style: TextStyle(
                          color: rankColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    if (result.myRank > 0) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('第 ${result.myRank} 名',
                            style: const TextStyle(
                                color: Color(0xFF8B949E), fontSize: 13)),
                      ),
                    ],
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${result.mmr.toStringAsFixed(0)} MMR',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text('${result.rankPoints.toStringAsFixed(0)} 分',
                            style: const TextStyle(
                                color: Color(0xFF8B949E), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 胜率进度条
                Row(
                  children: [
                    Text('胜率 $winPct%',
                        style: TextStyle(
                            color: result.winCount >= (result.loseCount)
                                ? const Color(0xFF2EA043)
                                : const Color(0xFF8B949E),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('共 $total 场',
                        style: const TextStyle(
                            color: Color(0xFF8B949E), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0
                        ? (result.winCount / total).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 7,
                    backgroundColor:
                        const Color(0xFFDA3633).withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF2EA043)),
                  ),
                ),
                const SizedBox(height: 14),

                // 胜/负/总
                Row(
                  children: [
                    _CountBox('胜', '${result.winCount}', const Color(0xFF2EA043)),
                    const SizedBox(width: 8),
                    _CountBox('负', '${result.loseCount}', const Color(0xFFDA3633)),
                    const SizedBox(width: 8),
                    _CountBox('总', '$total', const Color(0xFF8B949E)),
                  ],
                ),
              ],
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('本赛季暂无天梯数据',
                    style: TextStyle(color: Color(0xFF8B949E), fontSize: 14)),
              ),
            ),
    );
  }
}

// ── Debug 卡片 ─────────────────────────────────────────────────────────────

class _DebugCard extends StatelessWidget {
  final AuthProvider auth;
  const _DebugCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final rust   = auth.lastRustData;
    final mall   = auth.lastMallData;
    final ladder = auth.lastLadderData;
    final err    = auth.profileLoadError;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF444C56)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔧 API 调试信息',
              style: TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _DebugRow('rustwar', rust.isNotEmpty ? '✓ ${rust.keys.join(', ')}' : '✗ 空'),
          _DebugRow('mall4j',  mall.isNotEmpty ? '✓ ${mall.keys.join(', ')}' : '✗ 空/失败'),
          _DebugRow('ladder',  ladder.isNotEmpty ? '✓ ${ladder.keys.join(', ')}' : '✗ 空/失败'),
          if (err.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(err,
                  style: const TextStyle(
                      color: Color(0xFFFF7B72), fontSize: 10)),
            ),
        ],
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  final String label;
  final String value;
  const _DebugRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 10)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Color(0xFFCDD9E5), fontSize: 10)),
        ),
      ],
    ),
  );
}

// ── 小组件 ─────────────────────────────────────────────────────────────────

class _CountBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CountBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
