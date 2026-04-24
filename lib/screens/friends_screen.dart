import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../api/client.dart';
import '../models/match.dart';
import 'match_detail_screen.dart';
import 'user_match_history_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _searching  = false;
  String _searchError = '';

  // Search result (null = showing own matches)
  PlayerProfile? _foundProfile;

  // Own match history
  List<MatchRecord> _ownMatches  = [];
  bool   _ownLoading = false;
  bool   _ownHasMore = true;
  int    _ownPage    = 1;
  String _ownError   = '';
  String _selfUserId = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSelf());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_foundProfile != null) return; // searching mode – no scroll load
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadOwnMore();
    }
  }

  Future<void> _initSelf() async {
    final auth = context.read<AuthProvider>();
    _selfUserId = auth.api.userId;
    await _loadOwnMore();
  }

  Future<void> _loadOwnMore() async {
    if (_ownLoading || !_ownHasMore || _selfUserId.isEmpty) return;
    setState(() { _ownLoading = true; _ownError = ''; });
    try {
      final api = context.read<AuthProvider>().api;
      final raw = await api.matchHistoryForUser(
          _selfUserId, page: _ownPage, perPage: 20);
      final items = raw.map((e) => MatchRecord.fromJson(
          e as Map<String, dynamic>, selfUserId: _selfUserId)).toList();
      if (mounted) {
        setState(() {
          _ownMatches.addAll(items);
          _ownHasMore = items.length >= 20;
          _ownPage++;
          _ownLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _ownError = e.toString(); _ownLoading = false; });
    }
  }

  Future<void> _refreshOwn() async {
    setState(() { _ownMatches = []; _ownHasMore = true; _ownPage = 1; _ownError = ''; });
    await _loadOwnMore();
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() { _foundProfile = null; _searchError = ''; });
      return;
    }
    setState(() { _searching = true; _searchError = ''; _foundProfile = null; });
    try {
      final api = context.read<AuthProvider>().api;
      final data = int.tryParse(query) != null
          ? await api.searchPlayer(query)
          : await api.searchPlayerByName(query);

      if (data.isEmpty) throw Exception('未找到该玩家');

      final profile = PlayerProfile.fromJson(data);
      if (mounted) setState(() { _foundProfile = profile; _searching = false; });
    } catch (e) {
      if (mounted) setState(() {
        _searchError = '未找到玩家：${e.toString().replaceFirst('Exception: ', '')}';
        _searching   = false;
      });
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() { _foundProfile = null; _searchError = ''; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final api  = auth.api;
    final bool hasResult = _foundProfile != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Text(
          hasResult ? '搜索玩家' : '我的战绩',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: hasResult
            ? [
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF8B949E)),
                  tooltip: '返回',
                  onPressed: _clearSearch,
                )
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)),
                  onPressed: _refreshOwn,
                ),
              ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
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
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Color(0xFF8B949E), size: 18),
                            onPressed: _clearSearch)
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF161B22),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFF30363D))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFF30363D))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFE8A020))),
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
            ]),
          ),

          if (_searchError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(_searchError,
                  style: const TextStyle(
                      color: Color(0xFFDA3633), fontSize: 12)),
            ),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: hasResult
                ? _SearchResult(
                    profile: _foundProfile!,
                    api: api,
                  )
                : _OwnMatches(
                    matches:   _ownMatches,
                    loading:   _ownLoading,
                    hasMore:   _ownHasMore,
                    error:     _ownError,
                    api:       api,
                    selfId:    _selfUserId,
                    scroll:    _scrollCtrl,
                    onRefresh: _refreshOwn,
                    onRetry:   _loadOwnMore,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Search result: profile card + navigate button ──────────────────────────

class _SearchResult extends StatelessWidget {
  final PlayerProfile profile;
  final ApiClient api;
  const _SearchResult({required this.profile, required this.api});

  @override
  Widget build(BuildContext context) {
    final total   = profile.winCount + profile.loseCount;
    final winRate = total == 0 ? 0.0 : profile.winCount / total;
    final tc      = const Color(0xFFE8A020);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(children: [
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
                            profile.nickname.isEmpty
                                ? '玩家 #${profile.playerId}'
                                : profile.nickname,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Dota ID: ${profile.playerId}',
                              style: const TextStyle(
                                  color: Color(0xFF8B949E), fontSize: 12)),
                          if (profile.rankName.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _RankBadge(rankName: profile.rankName),
                          ],
                        ],
                      ),
                    ),
                  ]),

                  if (total > 0) ...[
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF30363D), height: 1),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _Stat('段位分',
                          profile.rankPoints.toStringAsFixed(0),
                          const Color(0xFFE8A020))),
                      Expanded(child: _Stat('MMR',
                          profile.mmr.toStringAsFixed(0),
                          const Color(0xFF58A6FF))),
                      Expanded(child: _Stat('胜率',
                          '${(winRate * 100).toStringAsFixed(1)}%',
                          winRate >= 0.5
                              ? const Color(0xFF2EA043)
                              : const Color(0xFFDA3633))),
                      Expanded(child: _Stat('胜场', '${profile.winCount}',
                          const Color(0xFF2EA043))),
                      Expanded(child: _Stat('败场', '${profile.loseCount}',
                          const Color(0xFFDA3633))),
                    ]),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Navigate to match history
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: profile.userId.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserMatchHistoryScreen(
                            userId:      profile.userId,
                            displayName: profile.nickname.isEmpty
                                ? '玩家 #${profile.playerId}'
                                : profile.nickname,
                            api: api,
                          ),
                        ),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: tc,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              icon: const Icon(Icons.sports_esports_outlined, size: 18),
              label: Text(
                profile.userId.isEmpty ? '无法获取战绩（userId缺失）' : '查看 TA 的战绩',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),

          if (profile.userId.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '调试：playerId=${profile.playerId}  userId="${profile.userId}"',
                style: const TextStyle(
                    color: Color(0xFF58A6FF), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Own match history list ─────────────────────────────────────────────────

class _OwnMatches extends StatelessWidget {
  final List<MatchRecord> matches;
  final bool loading;
  final bool hasMore;
  final String error;
  final ApiClient api;
  final String selfId;
  final ScrollController scroll;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;

  const _OwnMatches({
    required this.matches,
    required this.loading,
    required this.hasMore,
    required this.error,
    required this.api,
    required this.selfId,
    required this.scroll,
    required this.onRefresh,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty && loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8A020)));
    }
    if (matches.isEmpty && error.isNotEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline,
              color: Color(0xFF8B949E), size: 48),
          const SizedBox(height: 8),
          Text(error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8B949E))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ]),
      );
    }
    if (matches.isEmpty) {
      return const Center(
          child: Text('暂无战绩', style: TextStyle(color: Color(0xFF8B949E))));
    }

    return RefreshIndicator(
      color: const Color(0xFFE8A020),
      backgroundColor: const Color(0xFF161B22),
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: matches.length + (loading || hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == matches.length) {
            if (error.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(error,
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 12)),
                  const SizedBox(width: 8),
                  TextButton(
                      onPressed: onRetry,
                      child: const Text('重试',
                          style: TextStyle(color: Color(0xFFE8A020)))),
                ]),
              );
            }
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFE8A020)),
              ),
            );
          }
          return _MatchCard(match: matches[i], api: api);
        },
      ),
    );
  }
}

// ── Match card ─────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final MatchRecord match;
  final ApiClient api;
  const _MatchCard({required this.match, required this.api});

  Color get _color {
    if (match.isInvalid) return const Color(0xFF484F58);
    return match.isWin ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
  }

  String get _label {
    if (match.isInvalid) return '无效';
    return match.isWin ? '胜' : '负';
  }

  @override
  Widget build(BuildContext context) {
    final color   = _color;
    final dateStr = DateFormat('MM/dd HH:mm').format(match.startTime);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MatchDetailScreen(match: match, api: api),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(_label,
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
          ]),
        ),
      ),
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 3),
      Text(label,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 10)),
    ],
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
