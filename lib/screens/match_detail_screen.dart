import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/client.dart';
import '../models/match.dart';
import '../services/ai_summary_service.dart';
import '../services/model_manager.dart';
import 'user_match_history_screen.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class MatchDetailScreen extends StatefulWidget {
  final MatchRecord match;
  final ApiClient api;
  const MatchDetailScreen({super.key, required this.match, required this.api});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

enum _AiState { none, idle, downloading, loading, generating, done, error }

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  MatchDetail? _detail;
  bool _loading = true;
  String _error = '';
  String _debugInfo = '';

  // AI summary state
  _AiState _aiState = _AiState.none;
  double _downloadProgress = 0;
  String _summaryContent = '';

  bool get _userInMatch =>
      _detail?.players.any((p) => p.userId == widget.api.userId) ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; _debugInfo = ''; });
    try {
      final raw = await widget.api.settlement(widget.match.gameId);

      final topKeys = raw.keys.toList();
      final scores  = raw['scores'];
      final scoresType = scores?.runtimeType.toString() ?? 'null';
      String dbg = '顶层键: ${topKeys.join(', ')}\nscores类型: $scoresType';
      if (scores is Map) {
        dbg += '\nscores键: ${scores.keys.toList().join(', ')}';
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
        _initAiState();
      }
    } catch (e) {
      debugPrint('[settlement error] $e');
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _initAiState() async {
    if (!_userInMatch) return;
    final cached = await AiSummaryService.getCached(widget.match.gameId);
    if (!mounted) return;
    if (cached == null) {
      setState(() => _aiState = _AiState.idle);
    } else if (cached['status'] == 'done') {
      setState(() {
        _summaryContent = cached['content'] as String? ?? '';
        _aiState = _AiState.done;
      });
    } else {
      setState(() => _aiState = _AiState.idle);
    }
  }

  Future<void> _onAiTap() async {
    if (_aiState == _AiState.done) {
      _showSummarySheet();
      return;
    }
    if (_aiState != _AiState.idle && _aiState != _AiState.error) return;

    final downloaded = await ModelManager.isDownloaded();
    if (!downloaded) {
      final choice = await _showModelSourceDialog();
      if (!mounted || choice == null) return;
      if (choice == _ModelSource.network) {
        await _downloadFromNetwork();
      } else {
        await _importFromLocal();
      }
      if (!mounted || _aiState == _AiState.error || _aiState == _AiState.idle) return;
    }
    await _generate();
  }

  Future<_ModelSource?> _showModelSourceDialog() {
    return showDialog<_ModelSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(children: [
          Icon(Icons.auto_awesome, color: Color(0xFF58A6FF), size: 18),
          SizedBox(width: 8),
          Text('加载 AI 模型',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: const Text(
          '首次使用需要加载 Gemma 3B 模型文件（约 1.7 GB）',
          style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消',
                style: TextStyle(color: Color(0xFF8B949E))),
          ),
          _DialogButton(
            icon: Icons.folder_open,
            label: '本地导入',
            onTap: () => Navigator.pop(ctx, _ModelSource.local),
          ),
          _DialogButton(
            icon: Icons.cloud_download_outlined,
            label: '网络下载',
            onTap: () => Navigator.pop(ctx, _ModelSource.network),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFromNetwork() async {
    setState(() { _aiState = _AiState.downloading; _downloadProgress = 0; });
    try {
      await for (final pct in ModelManager.downloadFromNetwork()) {
        if (mounted) setState(() => _downloadProgress = pct / 100.0);
      }
    } catch (e) {
      if (mounted) setState(() => _aiState = _AiState.error);
      _showError('模型下载失败：$e');
    }
  }

  Future<void> _importFromLocal() async {
    setState(() => _aiState = _AiState.loading);
    try {
      final result = await ModelManager.importFromLocal();
      if (!mounted) return;
      switch (result) {
        case ImportResult.cancelled:
          setState(() => _aiState = _AiState.idle);
        case ImportResult.notFound:
          setState(() => _aiState = _AiState.error);
          _showError('文件不存在，请重新选择');
        case ImportResult.success:
          break; // 继续走 _generate
      }
    } catch (e) {
      if (mounted) setState(() => _aiState = _AiState.error);
      _showError('导入失败：$e');
    }
  }

  Future<void> _generate() async {
    setState(() => _aiState = _AiState.generating);
    try {
      final content = await AiSummaryService.generate(
        _detail!,
        widget.api.userId,
        widget.match.gameId,
      );
      if (mounted) {
        setState(() { _summaryContent = content; _aiState = _AiState.done; });
        _showSummarySheet();
      }
    } catch (e) {
      if (mounted) setState(() => _aiState = _AiState.error);
      _showError('AI 生成失败：$e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFDA3633)),
    );
  }

  void _showSummarySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => _SummarySheet(content: _summaryContent),
    );
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
          if (_aiState != _AiState.none) _AiButton(
            state: _aiState,
            progress: _downloadProgress,
            onTap: _onAiTap,
          ),
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
                  api: widget.api,
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
  final ApiClient api;

  const _DetailBody({
    required this.detail,
    required this.match,
    required this.selfUserId,
    required this.api,
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
                    api:       api,
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
  final ApiClient api;

  const _PlayerCard({
    required this.player,
    required this.isSelf,
    required this.isWinTeam,
    required this.totalDmg,
    required this.api,
  });

  @override
  Widget build(BuildContext context) {
    final p       = player;
    final tc      = isWinTeam ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
    final rpClr   = p.incRankPoints >= 0 ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
    final rpSign  = p.incRankPoints >= 0 ? '+' : '';
    final dmgPct  = totalDmg > 0 ? p.heroDamage / totalDmg * 100 : 0.0;
    final accent  = isSelf ? const Color(0xFFE8A020) : tc;
    final cardBg  = isSelf
        ? const Color(0xFFE8A020).withValues(alpha: 0.06)
        : const Color(0xFF161B22);

    // Flutter requires uniform border when borderRadius is set.
    // We achieve the colored left accent via an inner accent bar widget.
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF21262D), width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(width: 3, color: accent),
            // Content
            Expanded(
              child: ColoredBox(
                color: cardBg,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Row 1: MVP icon | avatar | hero+nick | KDA ──────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                          GestureDetector(
                            onTap: p.userId.isNotEmpty ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserMatchHistoryScreen(
                                  userId:      p.userId,
                                  playerId:    '',
                                  displayName: p.nickname.isNotEmpty
                                      ? p.nickname : p.heroName,
                                  avatar:      p.avatar,
                                  rankName:    p.rankName,
                                  api:         api,
                                ),
                              ),
                            ) : null,
                            child: CircleAvatar(
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
                                          color: _tierColor(p.rankName),
                                          fontSize: 10)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(text: '${p.kills}',
                                        style: const TextStyle(
                                            color: Color(0xFF3FB950))),
                                    const TextSpan(text: '/',
                                        style: TextStyle(
                                            color: Color(0xFF484F58),
                                            fontWeight: FontWeight.normal)),
                                    TextSpan(text: '${p.deaths}',
                                        style: const TextStyle(
                                            color: Color(0xFFFF7B72))),
                                    const TextSpan(text: '/',
                                        style: TextStyle(
                                            color: Color(0xFF484F58),
                                            fontWeight: FontWeight.normal)),
                                    TextSpan(text: '${p.assists}',
                                        style: const TextStyle(
                                            color: Color(0xFF79C0FF))),
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

                      // ── Row 2: 6 items + gold ─────────────────────────────
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

                      // ── Row 3: stat bar ──────────────────────────────────
                      Row(
                        children: [
                          Expanded(child: _StatCell(
                            label: '天梯积分',
                            value: p.rankPoints.toStringAsFixed(0),
                            sub: '$rpSign${p.incRankPoints.toStringAsFixed(0)}',
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
                            sub: '${dmgPct.toStringAsFixed(1)}%',
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
              ),
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
                      errorBuilder: (context, error, stack) => _nameText(),
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

// ── Model source choice ────────────────────────────────────────────────────

enum _ModelSource { network, local }

class _DialogButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DialogButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF58A6FF)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Color(0xFF58A6FF))),
      ],
    ),
  );
}

// ── AI button ──────────────────────────────────────────────────────────────

class _AiButton extends StatelessWidget {
  final _AiState state;
  final double progress;
  final VoidCallback onTap;

  const _AiButton({
    required this.state,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (label, active, showSpinner) = switch (state) {
      _AiState.idle       => ('AI智能总结',   true,  false),
      _AiState.downloading => ('下载 ${(progress * 100).toStringAsFixed(0)}%', false, true),
      _AiState.loading    => ('加载模型...',   false, true),
      _AiState.generating => ('生成中...',     false, true),
      _AiState.done       => ('查看AI总结',   true,  false),
      _AiState.error      => ('总结失败 重试', true,  false),
      _AiState.none       => ('',              false, false),
    };

    final color = state == _AiState.error
        ? const Color(0xFFDA3633)
        : const Color(0xFF58A6FF);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: GestureDetector(
          onTap: active ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: active ? 0.15 : 0.07),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: active ? 0.45 : 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSpinner) ...[
                  SizedBox(
                    width: 10, height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: color,
                      value: state == _AiState.downloading ? progress : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                ] else ...[
                  Icon(Icons.auto_awesome, size: 12, color: color),
                  const SizedBox(width: 4),
                ],
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary bottom sheet ────────────────────────────────────────────────────

class _SummarySheet extends StatelessWidget {
  final String content;
  const _SummarySheet({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF58A6FF), size: 16),
            const SizedBox(width: 8),
            const Text('AI 智能总结',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Color(0xFF8B949E), size: 20),
            ),
          ]),
          const SizedBox(height: 4),
          const Divider(color: Color(0xFF30363D)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Text(
              content,
              style: const TextStyle(
                  color: Color(0xFFCDD9E5),
                  fontSize: 14,
                  height: 1.65),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.smartphone, size: 11, color: Color(0xFF484F58)),
              const SizedBox(width: 4),
              const Text('由设备本地 AI 生成',
                  style: TextStyle(color: Color(0xFF484F58), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
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
