import 'package:flutter/material.dart';
import '../models/match.dart';

class AiSummaryResultPage extends StatelessWidget {
  final String content;
  final MatchDetail? detail;
  final String selfUserId;

  const AiSummaryResultPage({
    super.key,
    required this.content,
    this.detail,
    required this.selfUserId,
  });

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
        title: const Row(children: [
          Icon(Icons.auto_awesome, color: Color(0xFF58A6FF), size: 16),
          SizedBox(width: 8),
          Text('AI 智能总结',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (detail != null) ...[
            _MatchInfoCard(detail: detail!, selfUserId: selfUserId),
            const SizedBox(height: 12),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: SelectableText(
              content,
              style: const TextStyle(
                  color: Color(0xFFCDD9E5), fontSize: 15, height: 1.8),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.smartphone, size: 11, color: Color(0xFF484F58)),
              SizedBox(width: 4),
              Text('由设备本地 AI 生成',
                  style: TextStyle(color: Color(0xFF484F58), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchInfoCard extends StatelessWidget {
  final MatchDetail detail;
  final String selfUserId;
  const _MatchInfoCard({required this.detail, required this.selfUserId});

  @override
  Widget build(BuildContext context) {
    final self = detail.players
        .where((p) => p.userId == selfUserId)
        .cast<PlayerScore?>()
        .firstOrNull;
    if (self == null) return const SizedBox.shrink();

    final isWin = self.teamName == detail.winTeamName;
    final resultColor =
        isWin ? const Color(0xFF2EA043) : const Color(0xFFDA3633);
    final rpSign = self.incRankPoints >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF30363D),
            backgroundImage:
                self.avatar.isNotEmpty ? NetworkImage(self.avatar) : null,
            child: self.avatar.isEmpty
                ? Text(
                    self.heroName.isNotEmpty ? self.heroName[0] : '?',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  self.heroName.isNotEmpty ? self.heroName : self.nickname,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '${self.kills}/${self.deaths}/${self.assists}  伤害 ${self.heroDamage}',
                  style: const TextStyle(
                      color: Color(0xFF8B949E), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(isWin ? '胜利' : '失败',
                  style: TextStyle(
                      color: resultColor, fontWeight: FontWeight.bold)),
              Text(
                '$rpSign${self.incRankPoints.toStringAsFixed(0)} 分',
                style: TextStyle(color: resultColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
