import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/match.dart';
import '../screens/leaderboard_screen.dart' show _tierColor;

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
                  const SizedBox(height: 16),
                  _RankCard(profile: profile),
                  const SizedBox(height: 16),
                  _StatsCard(profile: profile),
                ],
              ),
            ),
    );
  }

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

// ── 头像卡片 ──────────────────────────────────────────────────────────────

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
            radius: 36,
            backgroundColor: const Color(0xFF30363D),
            backgroundImage: profile.avatar.isNotEmpty
                ? NetworkImage(profile.avatar)
                : null,
            child: profile.avatar.isEmpty
                ? const Icon(Icons.person,
                    size: 36, color: Color(0xFF8B949E))
                : null,
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 6),
                // 段位徽章
                _RankBadge(rankName: profile.rankName),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 段位卡片 ──────────────────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  final PlayerProfile profile;
  const _RankCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('段位信息',
              style: TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RankStat(
                  label: '段位分',
                  value: profile.rankPoints.toStringAsFixed(0),
                  color: const Color(0xFFE8A020),
                ),
              ),
              Expanded(
                child: _RankStat(
                  label: 'MMR',
                  value: profile.mmr.toStringAsFixed(0),
                  color: const Color(0xFF58A6FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 战绩卡片 ──────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final PlayerProfile profile;
  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final total   = profile.winCount + profile.loseCount;
    final winRate = profile.winRate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('战绩统计',
              style: TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 16),

          // 胜率进度条
          Row(
            children: [
              Text('胜率 ${(winRate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('共 $total 场',
                  style: const TextStyle(
                      color: Color(0xFF8B949E), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: winRate.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFDA3633).withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2EA043)),
            ),
          ),
          const SizedBox(height: 16),

          // 胜/负/总
          Row(
            children: [
              _CountBadge(
                  label: '胜', value: profile.winCount,
                  color: const Color(0xFF2EA043)),
              const SizedBox(width: 12),
              _CountBadge(
                  label: '负', value: profile.loseCount,
                  color: const Color(0xFFDA3633)),
              const SizedBox(width: 12),
              _CountBadge(
                  label: '总', value: total,
                  color: const Color(0xFF8B949E)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 小组件 ────────────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final String rankName;
  const _RankBadge({required this.rankName});

  @override
  Widget build(BuildContext context) {
    if (rankName.isEmpty) return const SizedBox.shrink();
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
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _RankStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RankStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold)),
    ],
  );
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CountBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value.toString(),
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8B949E), fontSize: 12)),
        ],
      ),
    ),
  );
}
