import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/client.dart';
import '../models/match.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class MatchDetailScreen extends StatefulWidget {
  final MatchRecord match;
  final ApiClient api;
  const MatchDetailScreen({super.key, required this.match, required this.api});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  MatchDetail? _detail;
  bool _loading = true;
  String _error = '';
  String _debugInfo = '';   // visible debug info when players is empty

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; _debugInfo = ''; });
    try {
      final raw = await widget.api.settlement(widget.match.gameId);

      // Collect debug info about the response structure
      final topKeys = raw.keys.toList();
      final scores  = raw['scores'];
      final scoresType = scores?.runtimeType.toString() ?? 'null';
      String dbg = '顶层键: ${topKeys.join(', ')}\nscores类型: $scoresType';
      if (scores is Map) {
        dbg += '\nscores键: ${(scores as Map).keys.toList().join(', ')}';
        final players = scores['players'];
        dbg += '\nplayers类型: ${players?.runtimeType ?? 'null'}';
        if (players is List) dbg += '  数量: ${players.length}';
      }
      debugPrint('[settlement debug] $dbg');

      if (mounted) {
        setState(() {
          _detail    = MatchDetail.fromJson(raw);
          _debugInfo = dbg;
          _loading   = false;
        });
      }
    } catch (e) {
      debugPrint('[settlement error] $e');
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final resultColor = m.isInvalid
        ? const Color(0xFF484F58)
        : m.isWin ? const Color(0xFF2EA043) : const Color(0xFFDA3633);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(children: [
          _TypeBadge('天梯排位'),
          const SizedBox(width: 6),
          _TypeBadge(m.matchType),
          const SizedBox(width: 14),
          Text(
            DateFormat('yyyy/MM/dd HH:mm').format(m.startTime),
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
          ),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: resultColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  m.isInvalid ? '无效' : m.isWin ? '胜利' : '失败',
                  style: TextStyle(
                      color: resultColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A020)))
          : _error.isNotEmpty
              ? _ErrorView(error: _error, onRetry: _load)
              : _DetailBody(
                  detail: _detail!,
                  match: m,
                  selfUserId: widget.api.userId,
                  debugInfo: _debugInfo,
                ),
    );
  }
}

// ── Detail body ────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final MatchDetail detail;
  final MatchRecord match;
  final String selfUserId;
  final String debugInfo;

  const _DetailBody({
    required this.detail,
    required this.match,
    required this.selfUserId,
    this.debugInfo = '',
  });

  @override
  Widget build(BuildContext context) {
    final teams = <String, List<PlayerScore>>{};
    for (final p in detail.players) {
      teams.putIfAbsent(p.teamName, () => []).add(p);
    }
    final sorted = teams.entries.toList()
      ..sort((a, b) {
        if (a.key == detail.winTeamName) return -1;
        if (b.key == detail.winTeamName) return 1;
        return 0;
      });

    final totalDmg = detail.players.fold(0, (s, p) => s + p.heroDamage);

    if (sorted.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBar(detail: detail, match: match),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('暂无详情数据',
                      style: TextStyle(color: Color(0xFF8B949E), fontSize: 14)),
                  if (debugInfo.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF30363D)),
                      ),
                      child: Text(debugInfo,
                          style: const TextStyle(
                              color: Color(0xFF58A6FF),
                              fontSize: 11,
                              fontFamily: 'monospace')),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _InfoBar(detail: detail, match: match),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final e in sorted) ...[
                _TeamHeader(
                  teamName:  e.key,
                  isWinTeam: e.key == detail.winTeamName,
                  kills:     e.value.fold(0, (s, p) => s + p.kills),
                ),
                for (final p in e.value)
                  _PlayerCard(
                    player:    p,
                    isSelf:    p.userId == selfUserId,
                    isWinTeam: e.key == detail.winTeamName,
                    totalDmg:  totalDmg,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info bar ───────────────────────────────────────────────────────────────

class _InfoBar extends StatelessWidget {
  final MatchDetail detail;
  final MatchRecord match;
  const _InfoBar({required this.detail, required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _InfoChip(Icons.timer_outlined, match.durationStr),
          if (detail.mode.isNotEmpty) ...[
            const SizedBox(width: 18),
            _InfoChip(Icons.sports_esports_outlined, detail.mode),
          ],
          if (detail.winTeamName.isNotEmpty) ...[
            const SizedBox(width: 18),
            const Icon(Icons.emoji_events_outlined,
                size: 14, color: Color(0xFFE8A020)),
            const SizedBox(width: 4),
            Text('${detail.winTeamName} 获胜',
                style: const TextStyle(color: Color(0xFFE8A020), fontSize: 12)),
          ],
          const Spacer(),
          Text('# ${match.gameId}',
              style: const TextStyle(color: Color(0xFF484F58), fontSize: 11)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: const Color(0xFF8B949E)),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
    ],
  );
}

// ── Team header ────────────────────────────────────────────────────────────

class _TeamHeader extends StatelessWidget {
  final String teamName;
  final bool isWinTeam;
  final int kills;
  const _TeamHeader({
    required this.teamName,
    required this.isWinTeam,
    required this.kills,
  });

  @override
  Widget build(BuildContext context) {
    final tc = isWinTeam ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
    return Container(
      color: tc.withValues(alpha: 0.07),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Container(width: 3, height: 14, color: tc,
            margin: const EdgeInsets.only(right: 8)),
        Text(teamName.isEmpty ? '队伍' : teamName,
            style: TextStyle(
                color: tc, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: tc.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(isWinTeam ? '胜' : '负',
              style: TextStyle(color: tc, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Icon(Icons.local_fire_department, size: 12, color: tc.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Text('$kills 击杀',
            style: TextStyle(color: tc.withValues(alpha: 0.8), fontSize: 11)),
      ]),
    );
  }
}

// ── Player card ─────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final PlayerScore player;
  final bool isSelf;
  final bool isWinTeam;
  final int totalDmg;

  const _PlayerCard({
    required this.player,
    required this.isSelf,
    required this.isWinTeam,
    required this.totalDmg,
  });

  @override
  Widget build(BuildContext context) {
    final p      = player;
    final tc     = isWinTeam ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
    final rpClr  = p.incRankPoints >= 0
        ? const Color(0xFF2EA043)
        : const Color(0xFFDA3633);
    final rpSign = p.incRankPoints >= 0 ? '+' : '';
    final dmgPct = totalDmg > 0 ? p.heroDamage / totalDmg * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: isSelf
            ? const Color(0xFFE8A020).withValues(alpha: 0.06)
            : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isSelf
                ? const Color(0xFFE8A020)
                : tc.withValues(alpha: 0.5),
            width: 3,
          ),
          top: BorderSide(color: const Color(0xFF21262D), width: 0.5),
          right: BorderSide(color: const Color(0xFF21262D), width: 0.5),
          bottom: BorderSide(color: const Color(0xFF21262D), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: icon | avatar | hero+nick+rank | KDA ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // MVP / MostKills indicator
                SizedBox(
                  width: 18,
                  child: p.mvpScore > 0
                      ? const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFE8A020))
                      : p.isMostKills
                          ? const Icon(Icons.military_tech,
                              size: 16, color: Color(0xFF58A6FF))
                          : null,
                ),
                const SizedBox(width: 6),
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF30363D),
                  backgroundImage: p.avatar.isNotEmpty
                      ? NetworkImage(p.avatar)
                      : null,
                  child: p.avatar.isEmpty
                      ? Text(
                          p.heroName.isNotEmpty ? p.heroName[0] : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                // Hero + Nickname + Rank
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.heroName.isEmpty ? p.nickname : p.heroName,
                        style: TextStyle(
                          color: isSelf
                              ? const Color(0xFFE8A020)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p.heroName.isNotEmpty)
                        Text(p.nickname,
                            style: const TextStyle(
                                color: Color(0xFF8B949E), fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      if (p.rankName.isNotEmpty)
                        Text(p.rankName,
                            style: TextStyle(
                                color: _tierColor(p.rankName), fontSize: 10)),
                    ],
                  ),
                ),
                // KDA
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(text: '${p.kills}',
                              style: const TextStyle(color: Color(0xFF3FB950))),
                          const TextSpan(text: '/',
                              style: TextStyle(color: Color(0xFF484F58),
                                  fontWeight: FontWeight.normal)),
                          TextSpan(text: '${p.deaths}',
                              style: const TextStyle(color: Color(0xFFFF7B72))),
                          const TextSpan(text: '/',
                              style: TextStyle(color: Color(0xFF484F58),
                                  fontWeight: FontWeight.normal)),
                          TextSpan(text: '${p.assists}',
                              style: const TextStyle(color: Color(0xFF79C0FF))),
                        ],
                      ),
                    ),
                    Text(
                      '${(p.participationRate * 100).toStringAsFixed(0)}% 参战',
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Row 2: Items + Gold ───────────────────────────────────────
            Row(
              children: [
                ...List.generate(6, (i) {
                  final name     = i < p.items.length      ? p.items[i]      : '';
                  final imageUrl = i < p.itemImages.length ? p.itemImages[i] : '';
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _ItemSlot(name: name, imageUrl: imageUrl),
                  );
                }),
                const Spacer(),
                const Icon(Icons.monetization_on,
                    size: 13, color: Color(0xFFFFD700)),
                const SizedBox(width: 3),
                Text(_fmt(p.gold),
                    style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 10),

            // ── Row 3: 6-cell stat bar ────────────────────────────────────
            Row(
              children: [
                Expanded(child: _StatCell(
                  label: '天梯积分',
                  value: p.rankPoints.toStringAsFixed(0),
                  sub:   '$rpSign${p.incRankPoints.toStringAsFixed(0)}',
                  subColor: rpClr,
                  color: Colors.white,
                )),
                Expanded(child: _StatCell(
                  label: '参战率',
                  value: '${(p.participationRate * 100).toStringAsFixed(0)}%',
                  color: const Color(0xFFCDD9E5),
                )),
                Expanded(child: _StatCell(
                  label: '正/反补',
                  value: '${p.lastHits}/${p.denies}',
                  color: const Color(0xFFCDD9E5),
                )),
                Expanded(child: _StatCell(
                  label: '伤害',
                  value: _fmt(p.heroDamage),
                  sub:   '${dmgPct.toStringAsFixed(1)}%',
                  subColor: const Color(0xFF8B949E),
                  color: const Color(0xFFFF7B72),
                )),
                Expanded(child: _StatCell(
                  label: '治疗',
                  value: _fmt(p.heroHealing),
                  color: const Color(0xFF3FB950),
                )),
                Expanded(child: _StatCell(
                  label: '推塔',
                  value: _fmt(p.towerDamage),
                  color: const Color(0xFF79C0FF),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _tierColor(String n) {
    if (n.contains('永恒') || n.contains('超凡')) return const Color(0xFFE74C3C);
    if (n.contains('神话') || n.contains('传奇')) return const Color(0xFF9B59B6);
    if (n.contains('宗师') || n.contains('大师')) return const Color(0xFFE8A020);
    if (n.contains('精英') || n.contains('黄金')) return const Color(0xFFFFD700);
    return const Color(0xFF8B949E);
  }

  String _fmt(int v) =>
      v >= 10000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';
}

// ── Stat cell ──────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color color;
  final Color? subColor;

  const _StatCell({
    required this.label,
    required this.value,
    this.sub,
    required this.color,
    this.subColor,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      if (sub != null)
        Text(sub!,
            style: TextStyle(
                color: subColor ?? const Color(0xFF8B949E),
                fontSize: 10),
            textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              color: Color(0xFF8B949E), fontSize: 9),
          textAlign: TextAlign.center),
    ],
  );
}

// ── Item slot ──────────────────────────────────────────────────────────────

class _ItemSlot extends StatelessWidget {
  final String name;
  final String imageUrl;
  const _ItemSlot({required this.name, this.imageUrl = ''});

  static const _size = 30.0;

  @override
  Widget build(BuildContext context) {
    final isEmpty  = name.isEmpty;
    final hasImage = imageUrl.isNotEmpty;

    return Tooltip(
      message: name,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: isEmpty ? const Color(0xFF1C2128) : const Color(0xFF2D3139),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isEmpty
                ? const Color(0xFF2D333B)
                : const Color(0xFF444C56),
          ),
        ),
        child: isEmpty
            ? const Icon(Icons.add, size: 10, color: Color(0xFF3D444D))
            : hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.network(
                      imageUrl,
                      width: _size,
                      height: _size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _nameText(),
                    ),
                  )
                : _nameText(),
      ),
    );
  }

  Widget _nameText() => Center(
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: Text(
        name,
        style: const TextStyle(
            color: Color(0xFFCDD9E5),
            fontSize: 6,
            fontWeight: FontWeight.w500,
            height: 1.1),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 3,
      ),
    ),
  );
}

// ── Type badge ─────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String label;
  const _TypeBadge(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFE8A020).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
          color: const Color(0xFFE8A020).withValues(alpha: 0.35)),
    ),
    child: Text(label,
        style: const TextStyle(
            color: Color(0xFFE8A020),
            fontSize: 11,
            fontWeight: FontWeight.w600)),
  );
}

// ── Error view ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline,
            color: Color(0xFF8B949E), size: 48),
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
