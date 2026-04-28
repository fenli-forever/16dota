import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../api/client.dart';
import '../models/match.dart';
import '../providers/friends_provider.dart';
import 'match_detail_screen.dart';

/// Displays match history for any given user (self or searched player).
class UserMatchHistoryScreen extends StatefulWidget {
  /// mall4j userId (from player_info.extid). May be empty for searched players.
  final String userId;
  /// Dota internal player ID (player_info.id). Always present when player is found.
  final String playerId;
  final String displayName;
  final String avatar;    // for adding to friends
  final String rankName;  // for adding to friends
  final ApiClient api;

  const UserMatchHistoryScreen({
    super.key,
    required this.userId,
    required this.playerId,
    required this.displayName,
    this.avatar   = '',
    this.rankName = '',
    required this.api,
  });

  @override
  State<UserMatchHistoryScreen> createState() => _UserMatchHistoryScreenState();
}

class _UserMatchHistoryScreenState extends State<UserMatchHistoryScreen> {
  final _scrollCtrl = ScrollController();

  List<MatchRecord> _matches = [];
  bool _loading = false;
  bool _hasMore = true;
  int  _page    = 1;
  String _error = '';
  String _activeId = ''; // whichever ID actually worked

  @override
  void initState() {
    super.initState();
    _activeId = widget.userId.isNotEmpty ? widget.userId : widget.playerId;
    _scrollCtrl.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<List<dynamic>> _fetch(String id, {bool isValid = true}) =>
      widget.api.matchHistoryForUser(id, page: _page, perPage: 20, isValid: isValid);

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() { _loading = true; _error = ''; });
    try {
      List<dynamic> raw;
      if (widget.userId.isNotEmpty) {
        try {
          raw = await _fetch(widget.userId);
          _activeId = widget.userId;
        } catch (_) {
          // mall4j userId failed — try Dota player ID as fallback
          if (widget.playerId.isNotEmpty) {
            raw = await _fetch(widget.playerId);
            _activeId = widget.playerId;
          } else {
            rethrow;
          }
        }
      } else if (widget.playerId.isNotEmpty) {
        // Try with playerId first (may be Dota player ID); if empty, retry without is_valid filter
        try {
          raw = await _fetch(widget.playerId);
          if (raw.isEmpty && _page == 1) {
            raw = await _fetch(widget.playerId, isValid: false);
          }
        } catch (_) {
          raw = await _fetch(widget.playerId, isValid: false);
        }
        _activeId = widget.playerId;
      } else {
        throw Exception('无法确定玩家 ID');
      }

      final items = raw.map((e) => MatchRecord.fromJson(
          e as Map<String, dynamic>, selfUserId: _activeId)).toList();
      if (mounted) {
        setState(() {
          _matches.addAll(items);
          _hasMore = items.length >= 20;
          _page++;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _refresh() async {
    setState(() { _matches = []; _hasMore = true; _page = 1; _error = ''; });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.displayName.isEmpty ? '玩家战绩' : widget.displayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(
              _activeId.isNotEmpty ? 'ID: $_activeId' : '战绩记录',
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Star button: add/remove friend (only when viewing someone else's history)
          if (widget.userId.isNotEmpty && widget.userId != widget.api.userId)
            Consumer<FriendsProvider>(
              builder: (_, friends, __) {
                final isFriend = friends.isFriend(widget.userId);
                return IconButton(
                  icon: Icon(
                    isFriend ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFriend
                        ? const Color(0xFFE8A020)
                        : const Color(0xFF8B949E),
                  ),
                  tooltip: isFriend ? '移除好友' : '加为好友',
                  onPressed: () {
                    if (isFriend) {
                      friends.removeFriend(widget.userId);
                    } else {
                      friends.addFriend(FriendEntry(
                        userId:   widget.userId,
                        nickname: widget.displayName,
                        avatar:   widget.avatar,
                        rankName: widget.rankName,
                      ));
                    }
                  },
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)),
            onPressed: _refresh,
          ),
        ],
      ),
      body: () {
        if (_matches.isEmpty && _loading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8A020)));
        }
        if (_matches.isEmpty && _error.isNotEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFF8B949E), size: 48),
              const SizedBox(height: 8),
              Text(_error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF8B949E))),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _refresh, child: const Text('重试')),
            ]),
          );
        }
        if (_matches.isEmpty) {
          return const Center(
              child: Text('暂无战绩', style: TextStyle(color: Color(0xFF8B949E))));
        }
        return RefreshIndicator(
          color: const Color(0xFFE8A020),
          backgroundColor: const Color(0xFF161B22),
          onRefresh: _refresh,
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: _matches.length + (_loading || _hasMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _matches.length) {
                if (_error.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error,
                            style: const TextStyle(
                                color: Color(0xFF8B949E), fontSize: 12)),
                        const SizedBox(width: 8),
                        TextButton(
                            onPressed: _loadMore,
                            child: const Text('重试',
                                style: TextStyle(color: Color(0xFFE8A020)))),
                      ],
                    ),
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
              return _MatchCard(match: _matches[i], api: widget.api);
            },
          ),
        );
      }(),
    );
  }
}

// ── Match card (same style as MatchHistoryScreen) ──────────────────────────

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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF21262D), width: 0.5),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: color),
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFF161B22),
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
                      ],
                    ),
                  ),
                ),
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
