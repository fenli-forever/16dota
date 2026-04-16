import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/match.dart';

Color _tierColor(String n) {
  if (n.contains('永恒') || n.contains('超凡')) return const Color(0xFFE74C3C);
  if (n.contains('神话') || n.contains('传奇')) return const Color(0xFF9B59B6);
  if (n.contains('宗师') || n.contains('大师')) return const Color(0xFFE8A020);
  if (n.contains('精英') || n.contains('黄金')) return const Color(0xFFFFD700);
  if (n.contains('白银') || n.contains('铂金')) return const Color(0xFF87CEEB);
  return const Color(0xFF8B949E);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text('我的',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)),
            tooltip: '刷新数据',
            onPressed: () => auth.refreshProfile(),
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
              onRefresh: () => auth.refreshProfile(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _AvatarCard(profile: profile),
                  const SizedBox(height: 12),
                  _RankCard(profile: profile),
                  const SizedBox(height: 12),
                  _StatsCard(profile: profile),
                  // Debug panel (only in debug builds when data looks empty)
                  if (kDebugMode && _isDataEmpty(profile)) ...[
                    const SizedBox(height: 12),
                    _DebugCard(auth: auth),
                  ],
                  const SizedBox(height: 16),
                ],
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

// ── 头像 + 基本信息卡片 ────────────────────────────────────────────────────

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
          // 头像
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
                const SizedBox(height: 8),
                if (profile.rankName.isNotEmpty)
                  _RankBadge(rankName: profile.rankName)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF30363D),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('未定段',
                        style: TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 11)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 段位信息卡片 ───────────────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  final PlayerProfile profile;
  const _RankCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasData = profile.rankPoints > 0 || profile.mmr > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('段位信息',
                  style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const Spacer(),
              if (!hasData)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF30363D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('暂无数据',
                      style: TextStyle(
                          color: Color(0xFF8B949E), fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  label: '天梯积分',
                  value: hasData
                      ? profile.rankPoints.toStringAsFixed(0)
                      : '—',
                  color: const Color(0xFFE8A020),
                ),
              ),
              Container(
                  width: 1, height: 40, color: const Color(0xFF30363D)),
              Expanded(
                child: _StatBlock(
                  label: 'MMR',
                  value: hasData
                      ? profile.mmr.toStringAsFixed(0)
                      : '—',
                  color: const Color(0xFF58A6FF),
                ),
              ),
              if (profile.rankName.isNotEmpty) ...[
                Container(
                    width: 1, height: 40, color: const Color(0xFF30363D)),
                Expanded(
                  child: Column(
                    children: [
                      Text(profile.rankName,
                          style: TextStyle(
                              color: _tierColor(profile.rankName),
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      const Text('段位',
                          style: TextStyle(
                              color: Color(0xFF8B949E), fontSize: 11),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── 战绩统计卡片 ───────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final PlayerProfile profile;
  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final total   = profile.winCount + profile.loseCount;
    final winRate = profile.winRate;
    final hasData = total > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('战绩统计',
                  style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const Spacer(),
              if (!hasData)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF30363D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('暂无数据',
                      style: TextStyle(
                          color: Color(0xFF8B949E), fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 胜率行
          Row(
            children: [
              Text(
                hasData
                    ? '胜率 ${(winRate * 100).toStringAsFixed(1)}%'
                    : '胜率 —',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                hasData ? '共 $total 场' : '—',
                style: const TextStyle(
                    color: Color(0xFF8B949E), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hasData ? winRate.clamp(0.0, 1.0) : 0,
              minHeight: 8,
              backgroundColor:
                  const Color(0xFFDA3633).withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2EA043)),
            ),
          ),
          const SizedBox(height: 16),

          // 胜/负/总
          Row(
            children: [
              _CountBox(
                  label: '胜',
                  value: hasData ? '${profile.winCount}' : '—',
                  color: const Color(0xFF2EA043)),
              const SizedBox(width: 8),
              _CountBox(
                  label: '负',
                  value: hasData ? '${profile.loseCount}' : '—',
                  color: const Color(0xFFDA3633)),
              const SizedBox(width: 8),
              _CountBox(
                  label: '总',
                  value: hasData ? '$total' : '—',
                  color: const Color(0xFF8B949E)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Debug 卡片（仅 debug 模式 + 数据为空时显示）────────────────────────────

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
              style: const TextStyle(
                  color: Color(0xFF8B949E), fontSize: 10)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Color(0xFFCDD9E5), fontSize: 10)),
        ),
      ],
    ),
  );
}

// ── 小组件 ────────────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final String rankName;
  const _RankBadge({required this.rankName});

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(rankName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(rankName,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBlock(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11),
          textAlign: TextAlign.center),
    ],
  );
}

class _CountBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CountBox(
      {required this.label, required this.value, required this.color});

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
              style: const TextStyle(
                  color: Color(0xFF8B949E), fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
