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
            return Column(
              children: [
                _StatsSummary(matches: mp.matches),
                Expanded(
                  child: RefreshIndicator(
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
                  ),
                ),
              ],
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

  static const _winColor   = Color(0xFF2EA043);
  static const _loseColor  = Color(0xFFDA3633);
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
      initialChildSize: 0.9,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _Chip(widget.match.matchType),
                  const SizedBox(width: 8),
                  Text('# ${widget.match.gameId}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const Spacer(),
                  const Icon(Icons.timer_outlined,
                      size: 14, color: Color(0xFF8B949E)),
                  const SizedBox(width: 4),
                  Text(widget.match.durationStr,
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 13)),
                  const SizedBox(width: 8),
                  Text(DateFormat('MM/dd').format(widget.match.startTime),
                      style: const TextStyle(
                          color: Color(0xFF484F58), fontSize: 12)),
                ],
              ),
            ),
            const Divider(color: Color(0xFF30363D), height: 1),
            // 内容
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE8A020)))
                  : _error.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFF8B949E), size: 40),
                              const SizedBox(height: 8),
                              Text(_error,
                                  style: const TextStyle(
                                      color: Color(0xFF8B949E))),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: _load, child: const Text('重试')),
                            ],
                          ),
                        )
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

// ── 详情内容（Tab 布局）────────────────────────────────────────────────────

class _DetailContent extends StatefulWidget {
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
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final me = widget.detail.playerById(widget.selfUserId);
    final maxDmg = widget.detail.players
        .map((p) => p.heroDamage)
        .fold(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        // Tab 切换
        Container(
          color: const Color(0xFF0D1117),
          child: Row(
            children: [
              _TabBtn(
                  label: '我的表现',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0)),
              _TabBtn(
                  label: '全场数据',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1)),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF30363D)),
        Expanded(
          child: _tab == 0
              ? ListView(
                  controller: widget.scrollCtrl,
                  padding: const EdgeInsets.all(14),
                  children: [
                    if (me != null)
                      _MyStats(
                        me: me,
                        isWin: widget.isWin,
                        maxDmg: maxDmg,
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('未找到本人数据',
                              style: TextStyle(color: Color(0xFF8B949E))),
                        ),
                      ),
                  ],
                )
              : ListView(
                  controller: widget.scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  children: [
                    _PlayersTable(
                      players: widget.detail.players,
                      selfUserId: widget.selfUserId,
                      winTeamName: widget.detail.winTeamName,
                      maxDmg: maxDmg,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFFE8A020) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFFE8A020) : const Color(0xFF8B949E),
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    ),
  );
}

// ── 我的表现 ──────────────────────────────────────────────────────────────

class _MyStats extends StatelessWidget {
  final PlayerScore me;
  final bool isWin;
  final int maxDmg;
  const _MyStats({required this.me, required this.isWin, required this.maxDmg});

  @override
  Widget build(BuildContext context) {
    final color  = isWin ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
    final rpStr  = _signed(me.incRankPoints.toStringAsFixed(0), me.incRankPoints >= 0);
    final mmrStr = _signed(me.incMmr.toStringAsFixed(1), me.incMmr >= 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 英雄 / 玩家 头 ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF30363D),
                backgroundImage:
                    me.avatar.isNotEmpty ? NetworkImage(me.avatar) : null,
                child: me.avatar.isEmpty
                    ? Text(
                        me.heroName.isNotEmpty ? me.heroName[0] : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me.heroName.isEmpty ? me.nickname : me.heroName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    if (me.heroName.isNotEmpty)
                      Text(me.nickname,
                          style: const TextStyle(
                              color: Color(0xFF8B949E), fontSize: 12)),
                    const SizedBox(height: 4),
                    if (me.rankName.isNotEmpty)
                      Text(me.rankName,
                          style: TextStyle(
                              color: _tierColor(me.rankName), fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isWin ? '胜 利' : '失 败',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  if (me.isMostKills || me.mvpScore > 0) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: [
                        if (me.isMostKills)
                          _Badge('最多击杀', const Color(0xFFE8A020)),
                        if (me.mvpScore > 0)
                          _Badge(
                              'MVP ${me.mvpScore.toStringAsFixed(1)}',
                              const Color(0xFF58A6FF)),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── KDA ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _KdaBlock(
                      value: me.kills,
                      label: '击杀',
                      color: const Color(0xFF2EA043)),
                  Container(
                      width: 1, height: 44, color: const Color(0xFF30363D)),
                  _KdaBlock(
                      value: me.deaths,
                      label: '死亡',
                      color: const Color(0xFFDA3633)),
                  Container(
                      width: 1, height: 44, color: const Color(0xFF30363D)),
                  _KdaBlock(
                      value: me.assists,
                      label: '助攻',
                      color: const Color(0xFF58A6FF)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'KDA 比值 ${me.kda.toStringAsFixed(2)}  ·  '
                '参战率 ${(me.participationRate * 100).toStringAsFixed(0)}%  ·  '
                'Lv.${me.level}',
                style: const TextStyle(
                    color: Color(0xFF8B949E), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── 段位 / MMR / 金币 ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ChangeBlock(
                    label: '段位分',
                    value: rpStr,
                    positive: me.incRankPoints >= 0),
              ),
              Container(
                  width: 1, height: 32, color: const Color(0xFF30363D)),
              Expanded(
                child: _ChangeBlock(
                    label: 'MMR',
                    value: mmrStr,
                    positive: me.incMmr >= 0),
              ),
              Container(
                  width: 1, height: 32, color: const Color(0xFF30363D)),
              Expanded(
                child: Column(
                  children: [
                    Text(me.gold.toString(),
                        style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Text('金币',
                        style: TextStyle(
                            color: Color(0xFF8B949E), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── 伤害 / 治疗 / 推塔 ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _DmgBar(
                  label: '英雄伤害',
                  value: me.heroDamage,
                  max: maxDmg > 0 ? maxDmg : 1,
                  color: const Color(0xFFDA3633)),
              const SizedBox(height: 10),
              _DmgBar(
                  label: '治疗量',
                  value: me.heroHealing,
                  max: maxDmg > 0 ? maxDmg : 1,
                  color: const Color(0xFF2EA043)),
              const SizedBox(height: 10),
              _DmgBar(
                  label: '推塔伤害',
                  value: me.towerDamage,
                  max: maxDmg > 0 ? maxDmg : 1,
                  color: const Color(0xFF58A6FF)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: _MiniStat('补刀', me.lastHits.toString())),
                  Expanded(
                      child: _MiniStat('反补', me.denies.toString())),
                  Expanded(
                      child: _MiniStat('MVP得分',
                          me.mvpScore > 0
                              ? me.mvpScore.toStringAsFixed(1)
                              : '—')),
                ],
              ),
            ],
          ),
        ),

        // ── 装备 ────────────────────────────────────────────────────────
        if (me.items.where((s) => s.isNotEmpty).isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('装备',
                    style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: me.items
                      .where((s) => s.isNotEmpty)
                      .map((name) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFF30363D)),
                            ),
                            child: Text(name,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],

        // ── 符文 ────────────────────────────────────────────────────────
        if (me.runes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('符文',
                    style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: me.runes
                      .map((r) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFF58A6FF)
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Text('Lv${r.level} ${r.name}',
                                style: const TextStyle(
                                    color: Color(0xFF58A6FF),
                                    fontSize: 12)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  String _signed(String val, bool positive) =>
      positive ? '+$val' : val;

  Color _tierColor(String n) {
    if (n.contains('永恒') || n.contains('超凡')) return const Color(0xFFE74C3C);
    if (n.contains('神话') || n.contains('传奇')) return const Color(0xFF9B59B6);
    if (n.contains('宗师') || n.contains('大师')) return const Color(0xFFE8A020);
    if (n.contains('精英') || n.contains('黄金')) return const Color(0xFFFFD700);
    return const Color(0xFF8B949E);
  }
}

// ── 全场数据 ──────────────────────────────────────────────────────────────

class _PlayersTable extends StatelessWidget {
  final List<PlayerScore> players;
  final String selfUserId;
  final String winTeamName;
  final int maxDmg;
  const _PlayersTable({
    required this.players,
    required this.selfUserId,
    required this.winTeamName,
    required this.maxDmg,
  });

  @override
  Widget build(BuildContext context) {
    final teams = <String, List<PlayerScore>>{};
    for (final p in players) {
      teams.putIfAbsent(p.teamName, () => []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: teams.entries.map((e) {
        final teamName  = e.key;
        final isWinTeam = teamName == winTeamName;
        final teamColor = isWinTeam
            ? const Color(0xFF2EA043)
            : const Color(0xFFDA3633);
        final totalKills =
            e.value.fold(0, (sum, p) => sum + p.kills);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 队伍头
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: teamColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                      width: 3,
                      height: 16,
                      color: teamColor,
                      margin: const EdgeInsets.only(right: 8)),
                  Text(teamName.isEmpty ? '队伍' : teamName,
                      style: TextStyle(
                          color: teamColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: teamColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(isWinTeam ? '胜' : '负',
                        style: TextStyle(
                            color: teamColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  const Icon(Icons.local_fire_department,
                      size: 13, color: Color(0xFF8B949E)),
                  const SizedBox(width: 3),
                  Text('$totalKills 击杀',
                      style: const TextStyle(
                          color: Color(0xFF8B949E), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ...e.value.map((p) => _PlayerRow(
                  player: p,
                  isSelf: p.userId == selfUserId,
                  maxDmg: maxDmg,
                )),
            const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final PlayerScore player;
  final bool isSelf;
  final int maxDmg;
  const _PlayerRow(
      {required this.player, required this.isSelf, required this.maxDmg});

  @override
  Widget build(BuildContext context) {
    final p = player;
    final rpStr  = '${p.incRankPoints >= 0 ? '+' : ''}${p.incRankPoints.toStringAsFixed(0)}';
    final rpColor = p.incRankPoints >= 0
        ? const Color(0xFF2EA043)
        : const Color(0xFFDA3633);
    final dmgRatio =
        maxDmg > 0 ? (p.heroDamage / maxDmg).clamp(0.0, 1.0) : 0.0;
    final dmgStr = p.heroDamage >= 10000
        ? '${(p.heroDamage / 1000).toStringAsFixed(1)}k'
        : p.heroDamage.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isSelf
            ? const Color(0xFFE8A020).withValues(alpha: 0.07)
            : const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelf
              ? const Color(0xFFE8A020).withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF30363D),
                backgroundImage: p.avatar.isNotEmpty
                    ? NetworkImage(p.avatar)
                    : null,
                child: p.avatar.isEmpty
                    ? Text(
                        p.heroName.isNotEmpty ? p.heroName[0] : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              // 英雄名 + 玩家名
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.heroName.isEmpty ? p.nickname : p.heroName,
                      style: TextStyle(
                          color: isSelf
                              ? const Color(0xFFE8A020)
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.heroName.isNotEmpty)
                      Text(p.nickname,
                          style: const TextStyle(
                              color: Color(0xFF8B949E), fontSize: 10),
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // KDA
              SizedBox(
                width: 76,
                child: Text(
                  '${p.kills}/${p.deaths}/${p.assists}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12),
                ),
              ),
              // 段位变化
              SizedBox(
                width: 38,
                child: Text(rpStr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: rpColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // 伤害进度条
          Row(
            children: [
              const SizedBox(width: 42),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: dmgRatio,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF30363D),
                    valueColor: AlwaysStoppedAnimation(
                      isSelf
                          ? const Color(0xFFE8A020).withValues(alpha: 0.8)
                          : const Color(0xFFDA3633).withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 40,
                child: Text(dmgStr,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: Color(0xFF8B949E), fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 小组件 ────────────────────────────────────────────────────────────────

class _KdaBlock extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _KdaBlock(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value.toString(),
          style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              color: Color(0xFF8B949E), fontSize: 11)),
    ],
  );
}

class _ChangeBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool positive;
  const _ChangeBlock(
      {required this.label, required this.value, required this.positive});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: TextStyle(
              color: positive
                  ? const Color(0xFF2EA043)
                  : const Color(0xFFDA3633),
              fontSize: 18,
              fontWeight: FontWeight.bold)),
      Text(label,
          style: const TextStyle(
              color: Color(0xFF8B949E), fontSize: 11)),
    ],
  );
}

class _DmgBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  const _DmgBar(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = (value / max).clamp(0.0, 1.0);
    final valStr = value >= 10000
        ? '${(value / 1000).toStringAsFixed(1)}k'
        : value.toString();
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF8B949E), fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFF30363D),
              valueColor:
                  AlwaysStoppedAnimation(color.withValues(alpha: 0.8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(valStr,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ),
      ],
    );
  }
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
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600)),
      Text(label,
          style: const TextStyle(
              color: Color(0xFF484F58), fontSize: 10)),
    ],
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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

// ── 顶部统计摘要 ──────────────────────────────────────────────────────────

class _StatsSummary extends StatelessWidget {
  final List<MatchRecord> matches;
  const _StatsSummary({required this.matches});

  @override
  Widget build(BuildContext context) {
    final valid  = matches.where((m) => !m.isInvalid).toList();
    final wins   = valid.where((m) => m.isWin).length;
    final losses = valid.length - wins;
    final rate   = valid.isEmpty ? 0.0 : wins / valid.length;

    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SummaryItem('${valid.length}', '场', const Color(0xFF8B949E)),
          const SizedBox(width: 4),
          Container(
              width: 1, height: 24, color: const Color(0xFF30363D)),
          const SizedBox(width: 4),
          _SummaryItem('$wins', '胜', const Color(0xFF2EA043)),
          const SizedBox(width: 4),
          Container(
              width: 1, height: 24, color: const Color(0xFF30363D)),
          const SizedBox(width: 4),
          _SummaryItem('$losses', '负', const Color(0xFFDA3633)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '胜率 ${(rate * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                    color: rate >= 0.5
                        ? const Color(0xFF2EA043)
                        : const Color(0xFFDA3633),
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: rate.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor:
                        const Color(0xFFDA3633).withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF2EA043)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SummaryItem(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 2),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8B949E), fontSize: 12)),
      ],
    ),
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
