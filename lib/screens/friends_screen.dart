import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../api/client.dart';
import '../models/match.dart';
import 'match_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // Search state
  bool _searching = false;
  String _searchError = '';
  bool _isSearched = false;  // true when showing searched player, false = own

  // Profile + match history
  PlayerProfile? _profile;
  List<MatchRecord> _matches   = [];
  bool   _loadingMatches = false;
  bool   _hasMore        = true;
  int    _page           = 1;
  String _matchError     = '';
  String _targetUserId   = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // Load own profile + matches by default after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSelf());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMoreMatches();
    }
  }

  Future<void> _loadSelf() async {
    final auth = context.read<AuthProvider>();
    final api  = auth.api;
    _resetList(api.userId);
    // Use already-loaded profile if available
    if (auth.profile != null) {
      setState(() { _profile = auth.profile; });
    }
    await _loadMoreMatches();
  }

  void _resetList(String userId) {
    setState(() {
      _profile      = null;
      _matches      = [];
      _hasMore      = true;
      _page         = 1;
      _matchError   = '';
      _searchError  = '';
      _targetUserId = userId;
    });
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      // Clear search → go back to own matches
      _isSearched = false;
      _searchCtrl.clear();
      await _loadSelf();
      return;
    }

    setState(() { _searching = true; _searchError = ''; });

    try {
      final api = context.read<AuthProvider>().api;

      final data = int.tryParse(query) != null
          ? await api.searchPlayer(query)
          : await api.searchPlayerByName(query);

      if (data.isEmpty) throw Exception('未找到该玩家');

      final pi = data['player_info'] as Map<String, dynamic>? ?? data;
      final userId = pi['extid']?.toString()
          ?? pi['user_id']?.toString()
          ?? pi['userId']?.toString()
          ?? query;

      if (mounted) {
        _isSearched = true;
        _resetList(userId);
        setState(() {
          _profile   = PlayerProfile.fromJson(data);
          _searching = false;
        });
        _loadMoreMatches();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = '未找到玩家：${e.toString().replaceFirst('Exception: ', '')}';
          _searching   = false;
        });
      }
    }
  }

  Future<void> _loadMoreMatches() async {
    if (_loadingMatches || !_hasMore || _targetUserId.isEmpty) return;

    setState(() { _loadingMatches = true; _matchError = ''; });

    try {
      final api = context.read<AuthProvider>().api;
      final raw = await api.matchHistoryForUser(
        _targetUserId,
        page:    _page,
        perPage: 20,
      );
      final newItems = raw
          .map((e) => MatchRecord.fromJson(
                e as Map<String, dynamic>,
                selfUserId: _targetUserId,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _matches.addAll(newItems);
          _hasMore = newItems.length >= 20;
          _page++;
          _loadingMatches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _matchError    = e.toString();
          _loadingMatches = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<AuthProvider>().api;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Text(
          _isSearched ? '搜索玩家' : '我的战绩',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: _isSearched
            ? [
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF8B949E)),
                  tooltip: '返回我的战绩',
                  onPressed: () {
                    _searchCtrl.clear();
                    _isSearched = false;
                    _loadSelf();
                  },
                )
              ]
            : null,
      ),
      body: Column(
        children: [
          // ── 搜索栏 ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: '输入昵称或玩家 ID 搜索',
                      hintStyle: const TextStyle(color: Color(0xFF484F58)),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF8B949E)),
                      filled: true,
                      fillColor: const Color(0xFF161B22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFF30363D)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFF30363D)),
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
                      : const Text('搜索',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          if (_searchError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(_searchError,
                  style: const TextStyle(
                      color: Color(0xFFDA3633), fontSize: 12)),
            ),

          // ── 结果区 ──────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFE8A020),
              backgroundColor: const Color(0xFF161B22),
              onRefresh: () async {
                setState(() {
                  _matches    = [];
                  _hasMore    = true;
                  _page       = 1;
                  _matchError = '';
                });
                await _loadMoreMatches();
              },
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: EdgeInsets.zero,
                // 0 = profile card (optional), then match cards, then footer
                itemCount: (_profile != null ? 1 : 0) + _matches.length +
                    (_loadingMatches || (_hasMore && !_matchError.isNotEmpty) ? 1 : 0),
                itemBuilder: (ctx, i) {
                  // Profile header
                  if (_profile != null) {
                    if (i == 0) return _ProfileHeader(profile: _profile!);
                    i--;
                  }
                  // Footer loader / error
                  if (i == _matches.length) {
                    if (_matchError.isNotEmpty) {
                      return _MatchErrorRow(
                          error: _matchError,
                          onRetry: _loadMoreMatches);
                    }
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE8A020)),
                      ),
                    );
                  }
                  return _MatchCard(match: _matches[i], api: api);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 玩家信息头部 ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final PlayerProfile profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final total   = profile.winCount + profile.loseCount;
    final winRate = total == 0 ? 0.0 : profile.winCount / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          // Avatar + name + rank
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF30363D),
                backgroundImage: profile.avatar.isNotEmpty
                    ? NetworkImage(profile.avatar)
                    : null,
                child: profile.avatar.isEmpty
                    ? const Icon(Icons.person,
                        size: 30, color: Color(0xFF8B949E))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nickname.isEmpty ? 'Player' : profile.nickname,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
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

          if (total > 0) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF30363D), height: 1),
            const SizedBox(height: 14),

            // Stats row
            Row(
              children: [
                _Stat('段位分',
                    profile.rankPoints.toStringAsFixed(0),
                    const Color(0xFFE8A020)),
                _Stat('MMR',
                    profile.mmr.toStringAsFixed(0),
                    const Color(0xFF58A6FF)),
                _Stat('胜率',
                    '${(winRate * 100).toStringAsFixed(1)}%',
                    winRate >= 0.5
                        ? const Color(0xFF2EA043)
                        : const Color(0xFFDA3633)),
                _Stat('胜场', '${profile.winCount}',
                    const Color(0xFF2EA043)),
                _Stat('败场', '${profile.loseCount}',
                    const Color(0xFFDA3633)),
              ],
            ),
          ],
        ],
      ),
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
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8B949E), fontSize: 10)),
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

// ── 战绩卡片（与战绩页一致）──────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final MatchRecord match;
  final ApiClient api;
  const _MatchCard({required this.match, required this.api});

  Color get _resultColor {
    if (match.isInvalid) return const Color(0xFF484F58);
    return match.isWin ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
  }

  String get _resultText {
    if (match.isInvalid) return '无效';
    return match.isWin ? '胜' : '负';
  }

  @override
  Widget build(BuildContext context) {
    final color   = _resultColor;
    final dateStr = DateFormat('MM/dd HH:mm').format(match.startTime);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchDetailScreen(match: match, api: api),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(_resultText,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _Chip(match.matchType),
                      const SizedBox(width: 6),
                      Text(dateStr,
                          style: const TextStyle(
                              color: Color(0xFF8B949E), fontSize: 12)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.timer_outlined,
                          size: 13, color: Color(0xFF484F58)),
                      const SizedBox(width: 3),
                      Text(match.durationStr,
                          style: const TextStyle(
                              color: Color(0xFF8B949E), fontSize: 12)),
                      if (match.remark.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.star_outline,
                            size: 13, color: Color(0xFF484F58)),
                        const SizedBox(width: 3),
                        Text(match.remark,
                            style: const TextStyle(
                                color: Color(0xFF8B949E), fontSize: 12)),
                      ],
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('#${match.gameId}',
                      style: const TextStyle(
                          color: Color(0xFF484F58), fontSize: 11)),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF484F58), size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFE8A020).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: const TextStyle(
            color: Color(0xFFE8A020),
            fontSize: 11,
            fontWeight: FontWeight.w600)),
  );
}

class _MatchErrorRow extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _MatchErrorRow({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(error,
            style: const TextStyle(
                color: Color(0xFF8B949E), fontSize: 12)),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onRetry,
          child: const Text('重试',
              style: TextStyle(color: Color(0xFFE8A020))),
        ),
      ],
    ),
  );
}
