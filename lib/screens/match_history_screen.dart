import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../models/match.dart';
import '../api/client.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});
  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  late MatchProvider _provider;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _provider = MatchProvider(context.read<AuthProvider>().api);
    _provider.load();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        _provider.load();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          backgroundColor: const Color(0xFF161B22),
          elevation: 0,
          title: const Text('战绩',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)),
              onPressed: () => _provider.load(refresh: true),
            ),
          ],
        ),
        body: Consumer<MatchProvider>(
          builder: (ctx, mp, _) {
            if (mp.loading && mp.matches.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE8A020)),
              );
            }
            if (mp.error.isNotEmpty && mp.matches.isEmpty) {
              return _ErrorView(
                error: mp.error,
                onRetry: () => mp.load(refresh: true),
              );
            }
            if (mp.matches.isEmpty) {
              return const Center(
                child: Text('暂无战绩',
                    style: TextStyle(color: Color(0xFF8B949E))),
              );
            }
            return RefreshIndicator(
              color: const Color(0xFFE8A020),
              backgroundColor: const Color(0xFF161B22),
              onRefresh: () => mp.load(refresh: true),
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: mp.matches.length + (mp.hasMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == mp.matches.length) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFE8A020)),
                      ),
                    );
                  }
                  return _MatchCard(
                    match: mp.matches[i],
                    api: context.read<AuthProvider>().api,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── 战绩卡片 ──────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final MatchRecord match;
  final ApiClient api;
  const _MatchCard({required this.match, required this.api});

  static const _winColor  = Color(0xFF2EA043);
  static const _loseColor = Color(0xFFDA3633);
  static const _invalColor = Color(0xFF484F58);

  Color get _resultColor {
    if (match.isInvalid) return _invalColor;
    return match.isWin ? _winColor : _loseColor;
  }

  String get _resultText {
    if (match.isInvalid) return '无效';
    return match.isWin ? '胜' : '负';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MM/dd HH:mm').format(match.startTime);
    final color   = _resultColor;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // 胜/负/无效 圆标
              Container(
                width: 38,
                height: 38,
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

              // 中间：模式 + 时间 + 时长
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Chip(match.matchType),
                        const SizedBox(width: 6),
                        Text(dateStr,
                            style: const TextStyle(
                                color: Color(0xFF8B949E), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
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
                      ],
                    ),
                  ],
                ),
              ),

              // 右侧：游戏 ID + 展开箭头
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

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(match: match, api: api),
    );
  }
}

// ── 详情底部弹窗 ──────────────────────────────────────────────────────────

class _DetailSheet extends StatefulWidget {
  final MatchRecord match;
  final ApiClient api;
  const _DetailSheet({required this.match, required this.api});
  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
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
      final raw    = await widget.api.settlement(widget.match.gameId);
      final detail = MatchDetail.fromJson(raw);
      if (mounted) setState(() { _detail = detail; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // 拖拽把手
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF30363D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _Chip(widget.match.matchType),
                  const SizedBox(width: 8),
                  Text('游戏 #${widget.match.gameId}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const Spacer(),
                  Text(widget.match.durationStr,
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF30363D), height: 1),
            // 内容
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFE8A020)))
                  : _error.isNotEmpty
                      ? Center(
                          child: Text(_error,
                              style: const TextStyle(
                                  color: Color(0xFF8B949E))))
                      : _DetailContent(
                          detail: _detail!,
                          selfUserId: widget.api.userId,
                          isWin: widget.match.isWin,
                          scrollCtrl: ctrl,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 详情内容 ──────────────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  final MatchDetail detail;
  final String selfUserId;
  final bool isWin;
  final ScrollController scrollCtrl;
  const _DetailContent({
    required this.detail,
    required this.selfUserId,
    required this.isWin,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final me = detail.playerById(selfUserId);
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      children: [
        // ── 本人核心数据 ──────────────────────────────────────────────
        if (me != null) ...[
          _MyStats(me: me, isWin: isWin, winTeam: detail.winTeamName),
          const SizedBox(height: 16),
        ],

        // ── 全场玩家列表 ──────────────────────────────────────────────
        _SectionTitle('全场玩家', icon: Icons.people_outline),
        const SizedBox(height: 8),
        _PlayersTable(
          players: detail.players,
          selfUserId: selfUserId,
          winTeamName: detail.winTeamName,
        ),
      ],
    );
  }
}

class _MyStats extends StatelessWidget {
  final PlayerScore me;
  final bool isWin;
  final String winTeam;
  const _MyStats({required this.me, required this.isWin, required this.winTeam});

  @override
  Widget build(BuildContext context) {
    final color = isWin ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
    final rpStr = me.incRankPoints >= 0
        ? '+${me.incRankPoints.toStringAsFixed(0)}'
        : me.incRankPoints.toStringAsFixed(0);
    final mmrStr = me.incMmr >= 0
        ? '+${me.incMmr.toStringAsFixed(1)}'
        : me.incMmr.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 英雄名 + 胜负
          Row(
            children: [
              // 头像占位
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF30363D),
                backgroundImage: me.avatar.isNotEmpty
                    ? NetworkImage(me.avatar) : null,
                child: me.avatar.isEmpty
                    ? const Icon(Icons.person, color: Color(0xFF8B949E), size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me.heroName.isEmpty ? me.nickname : me.heroName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(me.nickname,
                        style: const TextStyle(
                            color: Color(0xFF8B949E), fontSize: 12)),
                  ],
                ),
              ),
              // 胜负 + 段位
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(isWin ? '胜利' : '失败',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  const SizedBox(height: 4),
                  Text(me.rankName,
                      style: const TextStyle(
                          color: Color(0xFFE8A020), fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF30363D), height: 1),
          const SizedBox(height: 14),

          // KDA
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  label: 'KDA',
                  value: '${me.kills}/${me.deaths}/${me.assists}',
                  sub: me.kda.toStringAsFixed(2),
                ),
              ),
              Expanded(
                child: _BigStat(
                  label: '参战率',
                  value: '${(me.participationRate * 100).toStringAsFixed(0)}%',
                  sub: 'Lv.${me.level}',
                ),
              ),
              Expanded(
                child: _BigStat(
                  label: '段位分',
                  value: rpStr,
                  valueColor: me.incRankPoints >= 0
                      ? const Color(0xFF2EA043) : const Color(0xFFDA3633),
                  sub: '$mmrStr MMR',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 伤害 / 治疗 / 推塔 / 补刀
          Row(
            children: [
              Expanded(child: _MiniStat('英雄伤害', _fmt(me.heroDamage))),
              Expanded(child: _MiniStat('治疗量',  _fmt(me.heroHealing))),
              Expanded(child: _MiniStat('推塔伤害', _fmt(me.towerDamage))),
              Expanded(child: _MiniStat('补刀/反补',
                  '${me.lastHits}/${me.denies}')),
            ],
          ),

          // 特殊标记
          if (me.isMostKills || me.mvpScore > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (me.isMostKills)
                  _Badge('最多击杀', const Color(0xFFE8A020)),
                if (me.mvpScore > 0)
                  _Badge('MVP ${me.mvpScore.toStringAsFixed(1)}',
                      const Color(0xFF58A6FF)),
              ],
            ),
          ],

          // 装备
          if (me.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('装备',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: me.items
                  .where((s) => s.isNotEmpty)
                  .map((name) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF30363D),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                      ))
                  .toList(),
            ),
          ],

          // 符文
          if (me.runes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('符文',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: me.runes
                  .map((r) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF30363D),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Lv${r.level} ${r.name}',
                            style: const TextStyle(
                                color: Color(0xFF58A6FF), fontSize: 11)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ── 全场玩家表格 ──────────────────────────────────────────────────────────

class _PlayersTable extends StatelessWidget {
  final List<PlayerScore> players;
  final String selfUserId;
  final String winTeamName;
  const _PlayersTable({
    required this.players,
    required this.selfUserId,
    required this.winTeamName,
  });

  @override
  Widget build(BuildContext context) {
    final teams = <String, List<PlayerScore>>{};
    for (final p in players) {
      teams.putIfAbsent(p.teamName, () => []).add(p);
    }

    return Column(
      children: teams.entries.map((e) {
        final teamName = e.key;
        final isWinTeam = teamName == winTeamName;
        final teamColor = isWinTeam
            ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                      width: 3, height: 14,
                      color: teamColor,
                      margin: const EdgeInsets.only(right: 8)),
                  Text(teamName.isEmpty ? '队伍' : teamName,
                      style: TextStyle(
                          color: teamColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(isWinTeam ? '胜' : '负',
                      style: TextStyle(color: teamColor, fontSize: 12)),
                ],
              ),
            ),
            // 表头
            _TableRow(
              isSelf: false, isHeader: true,
              hero: '英雄', nick: '玩家',
              kda: 'KDA', damage: '伤害',
              rankPt: '段位分', rankName: '段位',
            ),
            ...e.value.map((p) => _TableRow(
              isSelf: p.userId == selfUserId,
              isHeader: false,
              hero: p.heroName,
              nick: p.nickname,
              kda: '${p.kills}/${p.deaths}/${p.assists}',
              damage: p.heroDamage >= 10000
                  ? '${(p.heroDamage / 1000).toStringAsFixed(1)}k'
                  : p.heroDamage.toString(),
              rankPt: '${p.incRankPoints >= 0 ? '+' : ''}${p.incRankPoints.toStringAsFixed(0)}',
              rankName: p.rankName,
              rankPtColor: p.incRankPoints >= 0
                  ? const Color(0xFF2EA043) : const Color(0xFFDA3633),
            )),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}

class _TableRow extends StatelessWidget {
  final bool isSelf;
  final bool isHeader;
  final String hero;
  final String nick;
  final String kda;
  final String damage;
  final String rankPt;
  final String rankName;
  final Color rankPtColor;

  const _TableRow({
    required this.isSelf,
    required this.isHeader,
    required this.hero,
    required this.nick,
    required this.kda,
    required this.damage,
    required this.rankPt,
    required this.rankName,
    this.rankPtColor = const Color(0xFF8B949E),
  });

  @override
  Widget build(BuildContext context) {
    final base = isHeader
        ? const TextStyle(color: Color(0xFF484F58), fontSize: 11)
        : TextStyle(
            color: isSelf ? const Color(0xFFE8A020) : Colors.white,
            fontSize: 12,
            fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
          );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: isSelf
          ? BoxDecoration(
              color: const Color(0xFFE8A020).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        children: [
          Expanded(flex: 3,
              child: Text(hero.isEmpty ? '—' : hero, style: base,
                  overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3,
              child: Text(nick.isEmpty ? '—' : nick, style: base,
                  overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3,
              child: Text(kda, style: base)),
          Expanded(flex: 2,
              child: Text(damage, style: base)),
          Expanded(flex: 2,
              child: Text(rankPt, style: isHeader ? base : base.copyWith(
                  color: rankPtColor))),
          Expanded(flex: 2,
              child: Text(rankName, style: base,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// ── 小组件 ────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionTitle(this.text, {required this.icon});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF8B949E)),
      const SizedBox(width: 6),
      Text(text,
          style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    ],
  );
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? valueColor;
  const _BigStat({
    required this.label,
    required this.value,
    required this.sub,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
      const SizedBox(height: 3),
      Text(value,
          style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold)),
      Text(sub,
          style: const TextStyle(color: Color(0xFF484F58), fontSize: 11)),
    ],
  );
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      Text(label,
          style: const TextStyle(color: Color(0xFF484F58), fontSize: 10)),
    ],
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );
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

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Color(0xFF8B949E), size: 48),
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
