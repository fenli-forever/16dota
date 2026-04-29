import 'package:flutter_gemma/flutter_gemma.dart';
import '../models/match.dart';
import 'inference_service.dart';
import 'summary_db.dart';

class AiSummaryService {
  static String _buildPrompt(MatchDetail detail, String selfUserId) {
    final self = detail.players.firstWhere(
      (p) => p.userId == selfUserId,
      orElse: () => detail.players.first,
    );

    final totalDmg = detail.players.fold(0, (s, p) => s + p.heroDamage);
    final selfDmgPct = totalDmg > 0
        ? '${(self.heroDamage / totalDmg * 100).toStringAsFixed(1)}%'
        : '0%';
    final selfPts = self.incRankPoints >= 0
        ? '+${self.incRankPoints.toStringAsFixed(0)}'
        : self.incRankPoints.toStringAsFixed(0);
    final winTeam = detail.winTeamName;
    final isWin = self.teamName == winTeam;

    // 只取关键统计，每名玩家一行简短格式，控制 token 数量
    final rows = detail.players.map((p) {
      final tag = p.userId == selfUserId ? '*' : ' ';
      return '$tag${p.nickname}(${p.heroName}): '
          '${p.kills}/${p.deaths}/${p.assists} 伤${p.heroDamage}';
    }).join('\n');

    return '中路大乱斗解说助手。规则：3级出门，只有中路，死不掉钱，复活快。'
        '核心看KDA和伤害占比，补刀无意义。\n'
        '结果：$winTeam胜，时长${detail.duration}，'
        '「${self.nickname}」${isWin ? "胜" : "败"}\n'
        '我方数据：${self.heroName} '
        '${self.kills}/${self.deaths}/${self.assists} '
        '伤害$selfDmgPct 参战${(self.participationRate * 100).toStringAsFixed(0)}% '
        '积分$selfPts\n'
        '全场：\n$rows\n'
        '请100字内分三点总结：①亮点或不足 ②队伍节奏 ③改进建议。直接输出，不加标题。';
  }

  static Future<String> generate(
    MatchDetail detail,
    String selfUserId,
    String gameId,
  ) async {
    final model = InferenceService.instance.model;
    if (model == null) throw Exception('推理服务未运行');

    await SummaryDb.save(gameId, 'generating');
    InferenceModelSession? session;
    try {
      session = await model.createSession(
        temperature: 0.7,
        topK: 40,
        randomSeed: 42,
      );
      await session.addQueryChunk(
        Message(text: _buildPrompt(detail, selfUserId), isUser: true),
      );
      final content = (await session.getResponse()).trim();
      await SummaryDb.save(gameId, 'done', content: content);
      return content;
    } catch (e) {
      await SummaryDb.save(gameId, 'error');
      rethrow;
    } finally {
      await session?.close();
    }
  }

  static Future<Map<String, dynamic>?> getCached(String gameId) =>
      SummaryDb.get(gameId);
}
