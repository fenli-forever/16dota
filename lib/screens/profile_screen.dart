import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
        title: const Text('我的', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF8B949E)),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: profile == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8A020)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 头像 + 昵称
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF30363D),
                        backgroundImage: profile.avatar.isNotEmpty
                            ? NetworkImage(profile.avatar)
                            : null,
                        child: profile.avatar.isEmpty
                            ? const Icon(Icons.person,
                                size: 40, color: Color(0xFF8B949E))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.nickname.isEmpty ? 'Player' : profile.nickname,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${profile.playerId}',
                        style: const TextStyle(
                            color: Color(0xFF8B949E), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 数据卡片
                Row(
                  children: [
                    _StatCard(label: '段位分', value: profile.rankPoints.toStringAsFixed(0)),
                    _StatCard(label: 'MMR',   value: profile.mmr.toStringAsFixed(0)),
                    _StatCard(
                      label: '胜率',
                      value: '${(profile.winRate * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatCard(label: '胜场', value: profile.winCount.toString()),
                    _StatCard(label: '败场', value: profile.loseCount.toString()),
                    _StatCard(
                      label: '总场',
                      value: (profile.winCount + profile.loseCount).toString(),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Color(0xFFE8A020),
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF8B949E), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
