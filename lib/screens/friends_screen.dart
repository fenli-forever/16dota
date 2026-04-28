import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../api/client.dart';
import '../models/match.dart';
import 'user_match_history_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  // userId → null(loading) | true(active today) | false(offline)
  final Map<String, bool?> _status = {};
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatuses());
  }

  Future<void> _loadStatuses({bool force = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    final provider = context.read<FriendsProvider>();
    final api      = context.read<AuthProvider>().api;
    final toCheck  = provider.friends
        .where((f) => force || !_status.containsKey(f.userId))
        .map((f) => f.userId)
        .toList();
    await Future.wait(toCheck.map((id) => _checkStatus(id, api)));
    _refreshing = false;
  }

  Future<void> _checkStatus(String userId, ApiClient api) async {
    try {
      final raw  = await api.matchHistoryForUser(userId, page: 1, perPage: 1);
      if (raw.isEmpty) {
        if (mounted) setState(() => _status[userId] = false);
        return;
      }
      final last    = MatchRecord.fromJson(
          raw.first as Map<String, dynamic>, selfUserId: userId);
      final active  = DateTime.now().difference(last.startTime).inHours < 24;
      if (mounted) setState(() => _status[userId] = active);
    } catch (_) {
      if (mounted) setState(() => _status[userId] = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _status.clear());
    _refreshing = false;
    await _loadStatuses(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendsProvider>();
    final api      = context.read<AuthProvider>().api;
    final friends  = provider.friends;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text('好友',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)),
            onPressed: _refresh,
          ),
        ],
      ),
      body: friends.isEmpty
          ? const _EmptyState()
          : RefreshIndicator(
              color: const Color(0xFFE8A020),
              backgroundColor: const Color(0xFF161B22),
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: friends.length,
                separatorBuilder: (_, __) => const Divider(
                    color: Color(0xFF21262D), height: 1, indent: 72),
                itemBuilder: (ctx, i) {
                  final f = friends[i];
                  return _FriendTile(
                    friend:   f,
                    isActive: _status[f.userId],
                    api:      api,
                    onRemove: () => provider.removeFriend(f.userId),
                  );
                },
              ),
            ),
    );
  }
}

// ── Friend tile ────────────────────────────────────────────────────────────

class _FriendTile extends StatelessWidget {
  final FriendEntry friend;
  final bool? isActive; // null=loading, true=today active, false=offline
  final ApiClient api;
  final VoidCallback onRemove;

  const _FriendTile({
    required this.friend,
    required this.isActive,
    required this.api,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isActive == true
        ? const Color(0xFF2EA043)
        : const Color(0xFF484F58);
    final statusText = isActive == null
        ? '...'
        : isActive!
            ? '今日活跃'
            : '离线';

    return Dismissible(
      key: ValueKey(friend.userId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFDA3633),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      onDismissed: (_) => onRemove(),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF30363D),
              backgroundImage: friend.avatar.isNotEmpty
                  ? NetworkImage(friend.avatar)
                  : null,
              child: friend.avatar.isEmpty
                  ? Text(
                      friend.nickname.isNotEmpty ? friend.nickname[0] : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFF0D1117), width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          friend.nickname.isNotEmpty ? friend.nickname : '玩家',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            if (friend.rankName.isNotEmpty) ...[
              Text(friend.rankName,
                  style: const TextStyle(
                      color: Color(0xFF8B949E), fontSize: 11)),
              const SizedBox(width: 8),
            ],
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(statusText,
                style: TextStyle(color: dotColor, fontSize: 11)),
          ],
        ),
        trailing: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserMatchHistoryScreen(
                userId:      friend.userId,
                playerId:    '',
                displayName: friend.nickname,
                avatar:      friend.avatar,
                rankName:    friend.rankName,
                api:         api,
              ),
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFE8A020),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          child: const Text('查看战绩',
              style:
                  TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_outlined,
                size: 64, color: Color(0xFF30363D)),
            const SizedBox(height: 16),
            const Text('暂无好友',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                '在战绩详情中点击其他玩家头像\n查看其战绩时可以添加好友 ★',
                style:
                    TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}
