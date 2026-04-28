import 'package:flutter_gemma/flutter_gemma.dart';
import '../models/match.dart';
import 'summary_db.dart';

class AiSummaryService {
  static InferenceModel? _model;

  static bool get isModelLoaded => _model != null;

  // 获取已缓存的模型，不存在则加载
  static Future<InferenceModel> _getModel() async {
    _model ??= await FlutterGemma.getActiveModel(maxTokens: 1024);
    return _model!;
  }

  // 卸载模型，释放内存
  static Future<void> closeModel() async {
    await _model?.close();
    _model = null;
  }

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
    final selfDmgPct = (() {
      final total = detail.players.fold(0, (s, p) => s + p.heroDamage);
      return total > 0
          ? '${(self.heroDamage / total * 100).toStringAsFixed(1)}%'
          : '0%';
    })();
    final winTeam = detail.winTeamName;
    final isWin = self.teamName == winTeam;

    return '你是一位「中路大乱斗」游戏解说助手。'
        '中路大乱斗规则：出门直接3级，只有中路，死亡不掉钱，复活快，双方不断团战直到分出胜负。'
        '核心指标是击杀/死亡/助攻、英雄伤害占比、参战率，补刀和经济参考意义不大。\n\n'
        '请帮玩家「${self.nickname}」总结这场对战，200字以内，分三点输出：'
        '①本局表现亮点或不足 ②队伍整体节奏 ③一条针对性改进建议。'
        '直接输出总结内容，不要加标题前缀。\n\n'
        '比赛结果：${detail.duration}，$winTeam 获胜，'
        '「${self.nickname}」所在队伍${isWin ? "胜利" : "失败"}\n\n'
        '「${self.nickname}」的数据（英雄：${self.heroName}，队伍：${self.teamName}）：\n'
        'KDA ${self.kills}/${self.deaths}/${self.assists}，'
        '参战率 ${(self.participationRate * 100).toStringAsFixed(0)}%，'
        '英雄伤害 ${self.heroDamage}（占全场 $selfDmgPct），'
        '积分变化 $selfPts\n'
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
      final model = await _getModel();
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
