import 'package:flutter_gemma/flutter_gemma.dart';
import '../models/match.dart';
import 'external_ai_service.dart';
import 'inference_service.dart';
import 'summary_db.dart';

class AiSummaryService {
  // ── 本地模型 prompt（精简，控制 token） ─────────────────────────────────

  static String _buildLocalPrompt(MatchDetail detail, String selfUserId) {
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

  // ── 外部模型 prompt（详细，充分利用云端大模型能力） ────────────────────

  static const _externalSystemPrompt = '你是一位专业的 Dota 2 中路大乱斗（Mid Only）比赛分析师。'
      '你需要根据提供的比赛数据，给出专业、详细、有洞察力的比赛分析。\n\n'
      '游戏规则：\n'
      '- 3级出门，只有中路一条线，死亡不掉钱，复活时间很短\n'
      '- 这是一个快节奏的对线模式，团战频繁\n'
      '- 补刀数（正/反补）在此模式下意义不大，核心指标是KDA、伤害占比、参战率\n'
      '- 天梯积分变动反映个人表现对胜负的影响\n\n'
      '分析要求：\n'
      '- 使用中文输出\n'
      '- 结构化分析，使用编号和小标题\n'
      '- 分析要具体到玩家和英雄，不要泛泛而谈\n'
      '- 给出可操作的改进建议\n';

  static String _buildExternalPrompt(MatchDetail detail, String selfUserId) {
    final self = detail.players.firstWhere(
      (p) => p.userId == selfUserId,
      orElse: () => detail.players.first,
    );

    final totalDmg = detail.players.fold(0, (s, p) => s + p.heroDamage);
    final totalHeal = detail.players.fold(0, (s, p) => s + p.heroHealing);
    final totalTowerDmg = detail.players.fold(0, (s, p) => s + p.towerDamage);
    final totalGold = detail.players.fold(0, (s, p) => s + p.gold);
    final isWin = self.teamName == detail.winTeamName;

    // 分队伍整理
    final teams = <String, List<PlayerScore>>{};
    for (final p in detail.players) {
      teams.putIfAbsent(p.teamName, () => []).add(p);
    }

    final teamSections = teams.entries.map((e) {
      final isWinTeam = e.key == detail.winTeamName;
      final tag = isWinTeam ? '【胜】' : '【负】';
      final teamKills = e.value.fold(0, (s, p) => s + p.kills);
      final teamDeaths = e.value.fold(0, (s, p) => s + p.deaths);
      final teamDmg = e.value.fold(0, (s, p) => s + p.heroDamage);
      final teamGold = e.value.fold(0, (s, p) => s + p.gold);

      final buf = StringBuffer();
      buf.writeln('$tag ${e.key}（击杀$teamKills/$teamDeaths 伤害$teamDmg 经济$teamGold）');
      for (final p in e.value) {
        final selfMark = p.userId == selfUserId ? ' ★' : '';
        final dmgPct = totalDmg > 0
            ? '${(p.heroDamage / totalDmg * 100).toStringAsFixed(1)}%'
            : '0%';
        final goldPct = totalGold > 0
            ? '${(p.gold / totalGold * 100).toStringAsFixed(1)}%'
            : '0%';
        final healPct = totalHeal > 0
            ? '${(p.heroHealing / totalHeal * 100).toStringAsFixed(1)}%'
            : '-';
        final rpSign = p.incRankPoints >= 0 ? '+' : '';

        buf.writeln('  ${p.nickname}（${p.heroName}）$selfMark');
        buf.writeln('    KDA: ${p.kills}/${p.deaths}/${p.assists}  '
            '参战率: ${(p.participationRate * 100).toStringAsFixed(0)}%');
        buf.writeln('    伤害: ${p.heroDamage}（$dmgPct）  '
            '治疗: ${p.heroHealing}（$healPct）  '
            '推塔: ${p.towerDamage}');
        buf.writeln('    经济: ${p.gold}（$goldPct）  '
            '等级: ${p.level}  '
            '正/反补: ${p.lastHits}/${p.denies}');
        buf.writeln('    天梯积分: ${p.rankPoints.toStringAsFixed(0)}  '
            '变动: $rpSign${p.incRankPoints.toStringAsFixed(0)}');
        if (p.mvpScore > 0) {
          buf.writeln('    MVP评分: ${p.mvpScore.toStringAsFixed(1)}');
        }
        if (p.items.isNotEmpty) {
          buf.writeln('    装备: ${p.items.join(", ")}');
        }
        if (p.runes.isNotEmpty) {
          buf.writeln('    符文: ${p.runes.map((r) => r.name).join(", ")}');
        }
      }
      return buf.toString();
    }).join('\n');

    return '请分析以下中路大乱斗比赛：\n\n'
        '【比赛概况】\n'
        '结果: ${detail.winTeamName} 获胜\n'
        '时长: ${detail.duration}\n'
        '模式: ${detail.mode}\n\n'
        '【我的表现】\n'
        '玩家: ${self.nickname}（${self.heroName}）\n'
        '结果: ${isWin ? "胜利" : "失败"}\n'
        'KDA: ${self.kills}/${self.deaths}/${self.assists}\n'
        '伤害占比: ${totalDmg > 0 ? (self.heroDamage / totalDmg * 100).toStringAsFixed(1) : "0"}%\n'
        '参战率: ${(self.participationRate * 100).toStringAsFixed(0)}%\n'
        '天梯积分变动: ${self.incRankPoints >= 0 ? "+" : ""}${self.incRankPoints.toStringAsFixed(0)}\n\n'
        '【全场数据】\n'
        '$teamSections\n'
        '请从以下维度进行详细分析：\n'
        '1. 比赛整体评价（胜负关键因素）\n'
        '2. 个人表现分析（亮点与不足，结合具体数据）\n'
        '3. 团队配合与节奏分析\n'
        '4. 装备选择评价（如有装备数据）\n'
        '5. 具体改进建议（针对当前玩家）\n';
  }

  // ── 生成入口 ──────────────────────────────────────────────────────────

  static Future<String> generate(
    MatchDetail detail,
    String selfUserId,
    String gameId,
  ) async {
    await SummaryDb.save(gameId, 'generating');

    try {
      final content = await _generateLocal(detail, selfUserId);
      await SummaryDb.save(gameId, 'done', content: content);
      return content;
    } catch (e) {
      await SummaryDb.save(gameId, 'error');
      rethrow;
    }
  }

  static Future<String> generateExternal(
    MatchDetail detail,
    String selfUserId,
    String gameId,
    ExternalAiConfig config,
  ) async {
    await SummaryDb.save(gameId, 'generating');

    try {
      final content = await ExternalAiService.chatWithSystem(
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
        model: config.model,
        systemPrompt: _externalSystemPrompt,
        userPrompt: _buildExternalPrompt(detail, selfUserId),
        temperature: 0.7,
        maxTokens: 4096,
      );
      await SummaryDb.save(gameId, 'done', content: content);
      return content;
    } catch (e) {
      await SummaryDb.save(gameId, 'error');
      rethrow;
    }
  }

  static Future<String> _generateLocal(
    MatchDetail detail,
    String selfUserId,
  ) async {
    final model = InferenceService.instance.model;
    if (model == null) throw Exception('推理服务未运行');

    InferenceModelSession? session;
    try {
      session = await model.createSession(
        temperature: 0.7,
        topK: 40,
        randomSeed: 42,
      );
      await session.addQueryChunk(
        Message(text: _buildLocalPrompt(detail, selfUserId), isUser: true),
      );
      return (await session.getResponse()).trim();
    } finally {
      await session?.close();
    }
  }

  static Future<Map<String, dynamic>?> getCached(String gameId) =>
      SummaryDb.get(gameId);
}
