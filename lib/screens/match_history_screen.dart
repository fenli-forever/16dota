import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../models/match.dart';
import '../api/client.dart';
import 'match_detail_screen.dart';

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchDetailScreen(match: match, api: api),
      ),
    );
  }
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
          Container(width: 1, height: 24, color: const Color(0xFF30363D)),
          const SizedBox(width: 4),
          _SummaryItem('$wins', '胜', const Color(0xFF2EA043)),
          const SizedBox(width: 4),
          Container(width: 1, height: 24, color: const Color(0xFF30363D)),
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
