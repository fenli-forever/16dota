import 'package:flutter_gemma/flutter_gemma.dart';
import '../models/match.dart';
import 'summary_db.dart';

class AiSummaryService {
  static String _buildPrompt(MatchDetail detail, String selfUserId) {
    final self = detail.players.firstWhere(
      (p) => p.userId == selfUserId,
      orElse: () => detail.players.first,
    );

    final rows = detail.players.map((p) {
      final pts = p.incRankPoints >= 0
          ? '+${p.incRankPoints.toStringAsFixed(0)}'
          : p.incRankPoints.toStringAsFixed(0);
      return '  ${p.nickname}(${p.heroName},${p.teamName}): '
          '${p.kills}/${p.deaths}/${p.assists} '
          '伤害${p.heroDamage} 金钱${p.gold} 积分$pts';
    }).join('\n');

    final selfItems = self.items.where((i) => i.isNotEmpty).join('、');
    final selfPts = self.incRankPoints >= 0
        ? '+${self.incRankPoints.toStringAsFixed(0)}'
        : self.incRankPoints.toStringAsFixed(0);

    return '你是一位 Dota 2 解说助手，帮玩家「${self.nickname}」总结一场天梯对战。'
        '请用200字以内的中文输出，分三点：①个人表现 ②团队优劣势 ③一条改进建议。'
        '直接输出总结，不要重复题目。\n\n'
        '比赛信息：时长 ${detail.duration}，${detail.winTeamName} 获胜\n\n'
        '${self.nickname} 的数据（${self.heroName}，${self.teamName}）：\n'
        'KDA ${self.kills}/${self.deaths}/${self.assists}，'
        '英雄伤害 ${self.heroDamage}，金钱 ${self.gold}，积分 $selfPts\n'
        '出装：$selfItems\n\n'
        '全场数据：\n$rows';
  }

  static Future<String> generate(
    MatchDetail detail,
    String selfUserId,
    String gameId,
  ) async {
    await SummaryDb.save(gameId, 'generating');
    InferenceModelSession? session;
    try {
      final model = await FlutterGemma.getActiveModel(maxTokens: 1024);
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
