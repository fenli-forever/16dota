import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/match.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching   = false;
  PlayerProfile? _result;
  String _error = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _searching = true; _result = null; _error = ''; });
    try {
      final api  = context.read<AuthProvider>().api;
      final data = await api.searchPlayer(query);
      setState(() { _result = PlayerProfile.fromJson(data); });
    } catch (e) {
      setState(() { _error = '未找到玩家'; });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text('搜索玩家',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: '输入玩家 ID',
                      hintStyle: const TextStyle(color: Color(0xFF484F58)),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF8B949E)),
                      filled: true,
                      fillColor: const Color(0xFF161B22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFE8A020)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _searching ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8A020),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _searching
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('查询',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // 结果
          Expanded(
            child: _result != null
                ? _ProfileCard(profile: _result!)
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_search,
                                color: Color(0xFF484F58), size: 48),
                            const SizedBox(height: 12),
                            Text(_error,
                                style: const TextStyle(
                                    color: Color(0xFF8B949E))),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.manage_search,
                                color: const Color(0xFF30363D), size: 64),
                            const SizedBox(height: 16),
                            const Text('输入玩家 ID 查询',
                                style: TextStyle(
                                    color: Color(0xFF484F58), fontSize: 15)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── 玩家信息卡 ────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final PlayerProfile profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final total   = profile.winCount + profile.loseCount;
    final winRate = total == 0 ? 0.0 : profile.winCount / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // 头像 + 昵称
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF30363D),
                    backgroundImage: profile.avatar.isNotEmpty
                        ? NetworkImage(profile.avatar)
                        : null,
                    child: profile.avatar.isEmpty
                        ? const Icon(Icons.person,
                            size: 32, color: Color(0xFF8B949E))
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('ID: ${profile.playerId}',
                            style: const TextStyle(
                                color: Color(0xFF8B949E), fontSize: 12)),
                        if (profile.rankName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _RankBadge(rankName: profile.rankName),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF30363D), height: 1),
              const SizedBox(height: 20),

              // 数据
              Row(
                children: [
                  _Stat('段位分', profile.rankPoints.toStringAsFixed(0),
                      const Color(0xFFE8A020)),
                  _Stat('MMR', profile.mmr.toStringAsFixed(0),
                      const Color(0xFF58A6FF)),
                  _Stat('胜率',
                      '${(winRate * 100).toStringAsFixed(1)}%',
                      winRate >= 0.5
                          ? const Color(0xFF2EA043)
                          : const Color(0xFFDA3633)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Stat('胜场', profile.winCount.toString(),
                      const Color(0xFF2EA043)),
                  _Stat('败场', profile.loseCount.toString(),
                      const Color(0xFFDA3633)),
                  _Stat('总场', total.toString(),
                      const Color(0xFF8B949E)),
                ],
              ),

              // 胜率进度条
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: winRate.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor:
                      const Color(0xFFDA3633).withValues(alpha: 0.3),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF2EA043)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8B949E), fontSize: 11)),
      ],
    ),
  );
}

class _RankBadge extends StatelessWidget {
  final String rankName;
  const _RankBadge({required this.rankName});

  Color _tierColor(String n) {
    if (n.contains('永恒') || n.contains('超凡')) return const Color(0xFFE74C3C);
    if (n.contains('神话') || n.contains('传奇')) return const Color(0xFF9B59B6);
    if (n.contains('宗师') || n.contains('大师')) return const Color(0xFFE8A020);
    if (n.contains('精英') || n.contains('黄金')) return const Color(0xFFFFD700);
    if (n.contains('白银') || n.contains('铂金')) return const Color(0xFF87CEEB);
    return const Color(0xFF8B949E);
  }

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
