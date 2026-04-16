import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/client.dart';
import '../models/match.dart';

// ── Table layout constants ─────────────────────────────────────────────────

class _Col {
  final String label;
  final double width;
  const _Col(this.label, this.width);
}

const _kMvpW    = 24.0;
const _kPlayerW = 220.0;
const _kItemsW  = 178.0; // 6 × 26px + 5 × 3px gap + some padding

const _statCols = <_Col>[
  _Col('参战率',   56),
  _Col('杀/死/助',  92),
  _Col('天梯积分',  84),
  _Col('正补/反补', 74),
  _Col('经济',     68),
  _Col('伤害',     90),
  _Col('治疗',     68),
  _Col('推塔',     68),
];

// 24 + 220 + 178 + (56+92+84+74+68+90+68+68) = 422 + 600 = 1022
const _kTableWidth = 1022.0;

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await widget.api.settlement(widget.match.gameId);
      if (mounted) {
        setState(() {
          _detail = MatchDetail.fromJson(raw);
          _loading = false;
        });
      }
    } catch (e) {
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
                ),
    );
  }
}

// ── Detail body ────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final MatchDetail detail;
  final MatchRecord match;
  final String selfUserId;

  const _DetailBody({
    required this.detail,
    required this.match,
    required this.selfUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Group players by team; win team first
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

    final totalDmg =
        detail.players.fold(0, (s, p) => s + p.heroDamage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info bar (duration / mode / win team)
        _InfoBar(detail: detail, match: match),
        // Stats table
        Expanded(
          child: SingleChildScrollView(           // vertical
            child: SingleChildScrollView(         // horizontal
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _kTableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ColumnHeader(),
                    ...sorted.map((e) => _TeamSection(
                      teamName:    e.key,
                      players:     e.value,
                      isWinTeam:   e.key == detail.winTeamName,
                      selfUserId:  selfUserId,
                      totalDmg:    totalDmg,
                    )),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
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
                style: const TextStyle(
                    color: Color(0xFFE8A020), fontSize: 12)),
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
      Text(text,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
    ],
  );
}

// ── Column header row ──────────────────────────────────────────────────────

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C2128),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          const SizedBox(width: _kMvpW),
          const SizedBox(
            width: _kPlayerW,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('玩家',
                  style: TextStyle(
                      color: Color(0xFF8B949E), fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(
            width: _kItemsW,
            child: Text('装备',
                style: TextStyle(
                    color: Color(0xFF8B949E), fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          ..._statCols.map((c) => SizedBox(
            width: c.width,
            child: Text(c.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF8B949E), fontSize: 11,
                    fontWeight: FontWeight.w600)),
          )),
        ],
      ),
    );
  }
}

// ── Team section ───────────────────────────────────────────────────────────

class _TeamSection extends StatelessWidget {
  final String teamName;
  final List<PlayerScore> players;
  final bool isWinTeam;
  final String selfUserId;
  final int totalDmg;

  const _TeamSection({
    required this.teamName,
    required this.players,
    required this.isWinTeam,
    required this.selfUserId,
    required this.totalDmg,
  });

  @override
  Widget build(BuildContext context) {
    final tc = isWinTeam
        ? const Color(0xFF2EA043)
        : const Color(0xFFDA3633);
    final kills = players.fold(0, (s, p) => s + p.kills);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team header
        Container(
          color: tc.withValues(alpha: 0.07),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              Container(
                  width: 3, height: 14, color: tc,
                  margin: const EdgeInsets.only(left: _kMvpW - 3, right: 8)),
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
                    style: TextStyle(
                        color: tc, fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Icon(Icons.local_fire_department,
                  size: 12, color: tc.withValues(alpha: 0.7)),
              const SizedBox(width: 3),
              Text('$kills 击杀',
                  style: TextStyle(
                      color: tc.withValues(alpha: 0.8), fontSize: 11)),
            ],
          ),
        ),
        // Player rows
        ...players.map((p) => _PlayerRow(
          player:    p,
          isSelf:    p.userId == selfUserId,
          isWinTeam: isWinTeam,
          totalDmg:  totalDmg,
        )),
      ],
    );
  }
}

// ── Player row ─────────────────────────────────────────────────────────────

class _PlayerRow extends StatelessWidget {
  final PlayerScore player;
  final bool isSelf;
  final bool isWinTeam;
  final int totalDmg;

  const _PlayerRow({
    required this.player,
    required this.isSelf,
    required this.isWinTeam,
    required this.totalDmg,
  });

  @override
  Widget build(BuildContext context) {
    final p       = player;
    final tc      = isWinTeam ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
    final rpColor = p.incRankPoints >= 0
        ? const Color(0xFF2EA043)
        : const Color(0xFFDA3633);
    final rpSign  = p.incRankPoints >= 0 ? '+' : '';
    final dmgPct  = totalDmg > 0
        ? p.heroDamage / totalDmg * 100
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isSelf
            ? const Color(0xFFE8A020).withValues(alpha: 0.05)
            : Colors.transparent,
        border: Border(
          bottom: const BorderSide(color: Color(0xFF21262D)),
          left: BorderSide(
            color: isSelf
                ? const Color(0xFFE8A020).withValues(alpha: 0.7)
                : tc.withValues(alpha: 0.45),
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── MVP / star indicator ──────────────────────────────────────
          SizedBox(
            width: _kMvpW,
            child: p.mvpScore > 0
                ? const Icon(Icons.star_rounded,
                    size: 15, color: Color(0xFFE8A020))
                : p.isMostKills
                    ? const Icon(Icons.military_tech,
                        size: 15, color: Color(0xFF58A6FF))
                    : null,
          ),

          // ── Player info ───────────────────────────────────────────────
          SizedBox(
            width: _kPlayerW,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF30363D),
                    backgroundImage: p.avatar.isNotEmpty
                        ? NetworkImage(p.avatar)
                        : null,
                    child: p.avatar.isEmpty
                        ? Text(
                            p.heroName.isNotEmpty ? p.heroName[0] : '?',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (p.heroName.isNotEmpty)
                          Text(p.nickname,
                              style: const TextStyle(
                                  color: Color(0xFF8B949E), fontSize: 10),
                              overflow: TextOverflow.ellipsis),
                        if (p.rankName.isNotEmpty)
                          Text(p.rankName,
                              style: TextStyle(
                                  color: _tierColor(p.rankName),
                                  fontSize: 9),
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Items (6 slots) ───────────────────────────────────────────
          SizedBox(
            width: _kItemsW,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 3,
                runSpacing: 3,
                children: List.generate(6, (i) {
                  final name = i < p.items.length ? p.items[i] : '';
                  return _ItemSlot(name: name);
                }),
              ),
            ),
          ),

          // ── 参战率 ────────────────────────────────────────────────────
          _Cell(
            width: _statCols[0].width,
            child: Text(
              '${(p.participationRate * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          // ── 杀/死/助 ──────────────────────────────────────────────────
          _Cell(
            width: _statCols[1].width,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: '${p.kills}',
                      style: const TextStyle(color: Color(0xFF3FB950))),
                  const TextSpan(text: '/',
                      style: TextStyle(
                          color: Color(0xFF484F58),
                          fontWeight: FontWeight.normal)),
                  TextSpan(text: '${p.deaths}',
                      style: const TextStyle(color: Color(0xFFFF7B72))),
                  const TextSpan(text: '/',
                      style: TextStyle(
                          color: Color(0xFF484F58),
                          fontWeight: FontWeight.normal)),
                  TextSpan(text: '${p.assists}',
                      style: const TextStyle(color: Color(0xFF79C0FF))),
                ],
              ),
            ),
          ),

          // ── 天梯积分 ──────────────────────────────────────────────────
          _Cell(
            width: _statCols[2].width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.rankPoints.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  '$rpSign${p.incRankPoints.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: rpColor, fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // ── 正补/反补 ─────────────────────────────────────────────────
          _Cell(
            width: _statCols[3].width,
            child: Text(
              '${p.lastHits}/${p.denies}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          // ── 经济 ──────────────────────────────────────────────────────
          _Cell(
            width: _statCols[4].width,
            child: Text(
              _fmt(p.gold),
              style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),

          // ── 伤害 ──────────────────────────────────────────────────────
          _Cell(
            width: _statCols[5].width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_fmt(p.heroDamage),
                    style: const TextStyle(
                        color: Color(0xFFFF7B72), fontSize: 12)),
                Text('${dmgPct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: Color(0xFF8B949E), fontSize: 10)),
              ],
            ),
          ),

          // ── 治疗 ──────────────────────────────────────────────────────
          _Cell(
            width: _statCols[6].width,
            child: Text(
              _fmt(p.heroHealing),
              style: const TextStyle(
                  color: Color(0xFF3FB950), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          // ── 推塔 ──────────────────────────────────────────────────────
          _Cell(
            width: _statCols[7].width,
            child: Text(
              _fmt(p.towerDamage),
              style: const TextStyle(
                  color: Color(0xFF79C0FF), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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

// ── Stat cell wrapper ──────────────────────────────────────────────────────

class _Cell extends StatelessWidget {
  final double width;
  final Widget child;
  const _Cell({required this.width, required this.child});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(child: child),
    ),
  );
}

// ── Item slot ──────────────────────────────────────────────────────────────

class _ItemSlot extends StatelessWidget {
  final String name;
  const _ItemSlot({required this.name});

  static const _w = 26.0;
  static const _h = 26.0;

  @override
  Widget build(BuildContext context) {
    final isEmpty = name.isEmpty;
    return Tooltip(
      message: name,
      child: Container(
        width: _w,
        height: _h,
        decoration: BoxDecoration(
          color: isEmpty
              ? const Color(0xFF1C2128)
              : const Color(0xFF2D3139),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isEmpty
                ? const Color(0xFF2D333B)
                : const Color(0xFF444C56),
          ),
        ),
        alignment: Alignment.center,
        child: isEmpty
            ? const Icon(Icons.add, size: 10, color: Color(0xFF3D444D))
            : Text(
                // abbreviate to first 3 chars for small slot
                name.length > 3 ? name.substring(0, 3) : name,
                style: const TextStyle(
                    color: Color(0xFFCDD9E5),
                    fontSize: 7,
                    fontWeight: FontWeight.w500,
                    height: 1.1),
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
                maxLines: 2,
              ),
      ),
    );
  }
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
