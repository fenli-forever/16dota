class RuneInfo {
  final String name;
  final String icon; // icon identifier, e.g. "dotamd_1" or "fw_1"
  final int level; // 1 or 2
  final String description;

  const RuneInfo({
    required this.name,
    required this.icon,
    required this.level,
    this.description = '',
  });

  String get imageUrl =>
      'https://cdn.16dota.com.cn/rune/$icon.png';

  // Lookup by name, optionally filtered by level
  static RuneInfo? lookup(String name, {int? level}) {
    if (level != null) {
      return _byNameLevel['$name@$level'];
    }
    return _byName[name];
  }

  static final Map<String, RuneInfo> _byName = () {
    final map = <String, RuneInfo>{};
    for (final r in kLevel1Runes) {
      map[r.name] = r;
    }
    for (final r in kLevel2Runes) {
      map[r.name] = r;
    }
    return map;
  }();

  static final Map<String, RuneInfo> _byNameLevel = () {
    final map = <String, RuneInfo>{};
    for (final r in kLevel1Runes) {
      map['${r.name}@${r.level}'] = r;
    }
    for (final r in kLevel2Runes) {
      map['${r.name}@${r.level}'] = r;
    }
    return map;
  }();

  static List<RuneInfo> allRunes = [...kLevel1Runes, ...kLevel2Runes];
}

const List<RuneInfo> kLevel1Runes = [
  RuneInfo(name: '大力', icon: 'dotamd_1', level: 1, description: '每次升级获得额外攻击力'),
  RuneInfo(name: '敏捷药水', icon: 'dotamd_2', level: 1, description: '增加敏捷属性'),
  RuneInfo(name: '力量药水', icon: 'dotamd_3', level: 1, description: '每点力量额外提供攻击力'),
  RuneInfo(name: '智力药水', icon: 'dotamd_4', level: 1, description: '每点智力额外提供攻击力'),
  RuneInfo(name: '嗜血', icon: 'dotamd_5', level: 1, description: '获得法术吸血和物理吸血'),
  RuneInfo(name: '迅捷', icon: 'dotamd_6', level: 1, description: '增加攻击速度'),
  RuneInfo(name: '万能狙击', icon: 'dotamd_7', level: 1, description: '增加攻击距离'),
  RuneInfo(name: '生命打击', icon: 'dotamd_8', level: 1, description: '攻击附带自身最大生命值的物理伤害'),
  RuneInfo(name: '敏捷积蓄', icon: 'dotamd_9', level: 1, description: '每次升级获得敏捷，且击杀获得敏捷奖励'),
  RuneInfo(name: '力量积蓄', icon: 'dotamd_10', level: 1, description: '每次升级获得力量，且击杀获得力量奖励'),
  RuneInfo(name: '智力积蓄', icon: 'dotamd_11', level: 1, description: '每次升级获得智力，且击杀获得智力奖励'),
  RuneInfo(name: '法师思维', icon: 'dotamd_12', level: 1, description: '增加技能增强'),
  RuneInfo(name: '冷却药水', icon: 'dotamd_13', level: 1, description: '增加冷却缩减'),
  RuneInfo(name: '忍耐', icon: 'dotamd_14', level: 1, description: '放弃1级符文，在选择2级符文时可多选一次'),
  RuneInfo(name: '快人一步', icon: 'dotamd_15', level: 1, description: '经验获得时额外获得加成'),
  RuneInfo(name: '慢慢长大', icon: 'dotamd_16', level: 1, description: '出兵后每1分钟获得生命值、攻击力和体积'),
  RuneInfo(name: '随机咯', icon: 'dotamd_17', level: 1, description: '随机获得1个2级符文'),
  RuneInfo(name: '暴击旋律', icon: 'dotamd_19', level: 1, description: '每次暴击获得攻速，持续数秒（可叠加）'),
  RuneInfo(name: '第四下', icon: 'dotamd_20', level: 1, description: '每攻击N次，获得攻击力加成，持续1次攻击'),
  RuneInfo(name: '小偷小摸', icon: 'dotamd_21', level: 1, description: '每次普攻造成移速减缓，且偷取目标金钱'),
  RuneInfo(name: '黑黄强化', icon: 'dotamd_22', level: 1, description: '黑黄持续时间提升，体积更大，伤害提升'),
  RuneInfo(name: '只能这么快', icon: 'dotamd_26', level: 1, description: '攻击间隔固定，攻速也提供同比的攻击力'),
  RuneInfo(name: '奴仆专家', icon: 'dotamd_28', level: 1, description: '召唤物生命值、攻击力、攻速提升'),
  RuneInfo(name: '随机分配', icon: 'dotamd_29', level: 1, description: '获得属性点，随机分配在3个属性上'),
  RuneInfo(name: '我还活着', icon: 'dotamd_30', level: 1, description: '受到致命伤害有概率原地复活并获得魔免'),
  RuneInfo(name: '专业1技能', icon: 'dotamd_39', level: 1, description: '1技能基础冷却降低'),
  RuneInfo(name: '专业2技能', icon: 'dotamd_40', level: 1, description: '2技能基础冷却降低'),
  RuneInfo(name: '专业3技能', icon: 'dotamd_41', level: 1, description: '3技能基础冷却降低'),
  RuneInfo(name: '终极大师', icon: 'dotamd_42', level: 1, description: '大招技能造成的伤害提高'),
  RuneInfo(name: '只会平A', icon: 'dotamd_43', level: 1, description: '禁用所有主动技能，普攻伤害和攻击距离提升'),
  RuneInfo(name: '巨人祝福', icon: 'dotamd_44', level: 1, description: '体积增加，每点力量额外提升生命值'),
  RuneInfo(name: '终极刷新', icon: 'dotamd_46', level: 1, description: '施法终极技能后有概率直接刷新终极技能'),
  RuneInfo(name: '近身战', icon: 'dotamd_47', level: 1, description: '攻击距离固定，受到的伤害减少'),
  RuneInfo(name: '双刀流', icon: 'dotamd_48', level: 1, description: '攻击伤害降低，但每次普攻会额外攻击一次'),
  RuneInfo(name: '起舞吧', icon: 'dotamd_49', level: 1, description: '移速没有上限且无视地形，攻击获得移速'),
  RuneInfo(name: '多重施法', icon: 'dotamd_51', level: 1, description: '每次施法有概率双重/三重施法'),
  RuneInfo(name: '超级嗜血', icon: 'dotamd_53', level: 1, description: '生命值低于阈值时额外获得物理和法术吸血'),
  RuneInfo(name: '终极唤醒', icon: 'dotamd_54', level: 1, description: '每次施法终极技能后会刷新全部基础技能'),
  RuneInfo(name: '随机符文', icon: 'dotamd_55', level: 1, description: '随机获得2个2级符文'),
  RuneInfo(name: '敏捷之王', icon: 'dotamd_56', level: 1, description: '敏捷增幅（白字和绿字都能享受增幅效果）'),
  RuneInfo(name: '力量之王', icon: 'dotamd_57', level: 1, description: '力量增幅（白字和绿字都能享受增幅效果）'),
  RuneInfo(name: '智力之王', icon: 'dotamd_58', level: 1, description: '智力增幅（白字和绿字都能享受增幅效果）'),
  RuneInfo(name: '超级狙击', icon: 'dotamd_59', level: 1, description: '大幅增加攻击距离'),
  RuneInfo(name: '无尽暴击', icon: 'dotamd_60', level: 1, description: '暴击伤害结果提升'),
  RuneInfo(name: '燃油伤害', icon: 'dotamd_61', level: 1, description: '每次造成技能伤害额外造成魔法伤害'),
  RuneInfo(name: '超级板甲', icon: 'dotamd_62', level: 1, description: '增加护甲'),
  RuneInfo(name: '控不住我', icon: 'dotamd_63', level: 1, description: '定期清除自身负面buff并回复生命值'),
  RuneInfo(name: '基础大师', icon: 'dotamd_65', level: 1, description: '终极技能被永久沉默，基础技能伤害提升'),
  RuneInfo(name: '远程打击', icon: 'dotamd_66', level: 1, description: '对远距离敌人造成伤害时结果提升'),
  RuneInfo(name: '全才', icon: 'dotamd_67', level: 1, description: '副主属性的每点属性也提供攻击力'),
  RuneInfo(name: '魔免大军', icon: 'dotamd_68', level: 1, description: '召唤物获得永久魔免和额外属性'),
  RuneInfo(name: '超级随机', icon: 'dotamd_69', level: 1, description: '选择N分钟后获得2个随机的3级符文'),
  RuneInfo(name: '贤者之石', icon: 'dotamd_70', level: 1, description: '增加施法距离'),
  RuneInfo(name: '自动反击', icon: 'dotamd_72', level: 1, description: '承受伤害后对周围敌人造成魔法伤害'),
  RuneInfo(name: '加强随机', icon: 'dotamd_73', level: 1, description: '随机获得1个3级符文'),
  RuneInfo(name: '混沌打击', icon: 'dotamd_75', level: 1, description: '攻击力加成在一定范围内波动'),
  RuneInfo(name: '格挡一下', icon: 'dotamd_76', level: 1, description: '增加生命回复，受伤时降低伤害'),
  RuneInfo(name: '亡灵堆积', icon: 'dotamd_77', level: 1, description: '周围英雄死亡将永久获得全属性'),
  RuneInfo(name: '智力大师', icon: 'dotamd_79', level: 1, description: '每点智力提供技能增强'),
  RuneInfo(name: '分身专家', icon: 'dotamd_80', level: 1, description: '幻象承受伤害降低，额外继承攻击力'),
  RuneInfo(name: '法力燃烧', icon: 'dotamd_81', level: 1, description: '造成的伤害会扣除目标魔法值'),
  RuneInfo(name: '悄悄滴', icon: 'dotamd_82', level: 1, description: '获得永久隐身且施法不显形'),
  RuneInfo(name: '超级回蓝', icon: 'dotamd_85', level: 1, description: '增加魔法值和魔法回复'),
  RuneInfo(name: '炽热之心', icon: 'dotamd_86', level: 1, description: '每秒对周围敌人造成魔法伤害'),
  RuneInfo(name: '暴击王者', icon: 'dotamd_87', level: 1, description: '将暴击技能几率提升'),
  RuneInfo(name: '弱点击破', icon: 'dotamd_88', level: 1, description: '攻击降低目标护甲并让目标被动无效'),
  RuneInfo(name: '超级飞鞋', icon: 'dotamd_89', level: 1, description: '移动速度固定为650，不受任何减速影响'),
  RuneInfo(name: '猎杀时刻', icon: 'dotamd_90', level: 1, description: '击杀英雄后刷新全部基础技能并恢复魔法值'),
  RuneInfo(name: '敏捷精通', icon: 'dotamd_91', level: 1, description: '增加敏捷属性'),
  RuneInfo(name: '力量精通', icon: 'dotamd_92', level: 1, description: '增加力量属性'),
  RuneInfo(name: '智力精通', icon: 'dotamd_93', level: 1, description: '增加智力属性'),
  RuneInfo(name: '治疗大师', icon: 'dotamd_94', level: 1, description: '治疗效果提升，且对周围敌方造成同等伤害'),
  RuneInfo(name: '坦克杀手', icon: 'dotamd_97', level: 1, description: '攻击附带目标最大生命值的神圣伤害'),
  RuneInfo(name: '拔苗助长', icon: 'dotamd_101', level: 1, description: '立即提升等级，但出兵后一段时间才能获得经验'),
  RuneInfo(name: '精准攻击', icon: 'dotamd_102', level: 1, description: '攻击无视目标护甲，击杀英雄提升效果'),
  RuneInfo(name: '法术精通', icon: 'dotamd_103', level: 1, description: '技能消耗降低'),
  RuneInfo(name: '力量的代价', icon: 'dotamd_105', level: 1, description: '随机获得3级符文，但前期伤害降低'),
  RuneInfo(name: '嗜血欲望', icon: 'dotamd_110', level: 1, description: '敌方英雄血量低时获得其视野并提升伤害'),
  RuneInfo(name: '肉食动物', icon: 'dotamd_111', level: 1, description: '每次攻击获得攻击力（可叠加）'),
  RuneInfo(name: '全知', icon: 'dotamd_112', level: 1, description: '获得高空和真实视野'),
  RuneInfo(name: '法术坦克', icon: 'dotamd_114', level: 1, description: '法术吸血对英雄效果提升'),
  RuneInfo(name: '固定炮台', icon: 'dotamd_115', level: 1, description: '基础移动速度降低'),
  RuneInfo(name: '想跑', icon: 'dotamd_116', level: 1, description: '周围英雄移速和攻速降低，攻击有丢失'),
  RuneInfo(name: '发财咯', icon: 'dotamd_117', level: 1, description: '获得的金币提高，不死亡也可以回家买装备'),
  RuneInfo(name: '打十个', icon: 'dotamd_118', level: 1, description: '获得溅射效果'),
  RuneInfo(name: '冰封领域', icon: 'dotamd_119', level: 1, description: '周围英雄无法获得治疗且攻速降低'),
  RuneInfo(name: '绝对输出', icon: 'dotamd_122', level: 1, description: '每N分钟获得攻击力和攻速（无限成长）'),
  RuneInfo(name: '魔抗大师', icon: 'dotamd_132', level: 1, description: '增加魔法抗性'),
];

const List<RuneInfo> kLevel2Runes = [
  RuneInfo(name: '射程专精', icon: 'fw_1', level: 2, description: '增加攻击距离，每提升等级获得额外攻击距离'),
  RuneInfo(name: '敏之精通', icon: 'fw_5', level: 2, description: '提升敏捷，每次升级额外提供敏捷'),
  RuneInfo(name: '力之精通', icon: 'fw_6', level: 2, description: '提升力量，每次升级额外提供力量'),
  RuneInfo(name: '智之精通', icon: 'fw_7', level: 2, description: '提升智力，每次升级额外提供智力'),
  RuneInfo(name: '额外攻击', icon: 'fw_12', level: 2, description: '每次攻击有概率额外攻击一次'),
  RuneInfo(name: '召唤之力', icon: 'fw_13', level: 2, description: '召唤物额外提升攻速和攻击力'),
  RuneInfo(name: '法之拷打', icon: 'fw_19', level: 2, description: '技能伤害会降低目标魔抗'),
  RuneInfo(name: '分裂之斧', icon: 'fw_21', level: 2, description: '对周围造成分裂伤害'),
  RuneInfo(name: '闪避王', icon: 'fw_32', level: 2, description: '有概率闪避任何伤害'),
  RuneInfo(name: '反击', icon: 'fw_38', level: 2, description: '受到普攻有概率立即反击'),
  RuneInfo(name: '雷电场', icon: 'fw_39', level: 2, description: '释放技能对周围目标造成魔法伤害'),
  RuneInfo(name: '格挡盾牌', icon: 'fw_43', level: 2, description: '物理格挡伤害，击杀英雄提升格挡效果'),
  RuneInfo(name: '防御大师', icon: 'fw_45', level: 2, description: '护甲和生命恢复提升，击杀英雄永久提升护甲'),
  RuneInfo(name: '敏捷之刃', icon: 'fw_50', level: 2, description: '每次攻击附带敏捷的神圣伤害'),
  RuneInfo(name: '智慧之刃', icon: 'fw_51', level: 2, description: '每次攻击附带智力的神圣伤害'),
  RuneInfo(name: '多重施法1', icon: 'fw_52', level: 2, description: '每次施法有概率施法多次'),
  RuneInfo(name: '超强火力', icon: 'fw_55', level: 2, description: '增加冷却缩减'),
  RuneInfo(name: '看脸1', icon: 'fw_56', level: 2, description: '施法技能有概率立即刷新该技能'),
  RuneInfo(name: '魔法惩戒者', icon: 'fw_57', level: 2, description: '魔抗提升，周围敌人施法时受到魔法伤害'),
  RuneInfo(name: '狙击王', icon: 'fw_58', level: 2, description: '提升射程'),
  RuneInfo(name: '暴力法师', icon: 'fw_60', level: 2, description: '智力提升，技能增强提升'),
  RuneInfo(name: '虚假的黑洞', icon: 'fw_62', level: 2, description: '获得技能：虚假的黑洞'),
  RuneInfo(name: '溅射使者', icon: 'fw_63', level: 2, description: '主属性提升，获得溅射效果'),
  RuneInfo(name: '护甲之盾', icon: 'fw_64', level: 2, description: '法术吸血，受普攻时反弹护甲的神圣伤害'),
  RuneInfo(name: '虚假的无敌斩', icon: 'fw_65', level: 2, description: '获得技能：虚假的无敌斩'),
  RuneInfo(name: '虚假的决斗', icon: 'fw_66', level: 2, description: '获得技能：虚假的决斗'),
  RuneInfo(name: '敏捷加强', icon: 'fw_68', level: 2, description: '敏捷提升，每点敏捷额外提供攻击力'),
  RuneInfo(name: '智力加强', icon: 'fw_69', level: 2, description: '智力提升，每点智力额外提供攻击力'),
  RuneInfo(name: '虚假的时间结界', icon: 'fw_70', level: 2, description: '获得技能：虚假的时间结界'),
  RuneInfo(name: '虚假的死亡一指', icon: 'fw_73', level: 2, description: '获得技能：虚假的死亡一指'),
  RuneInfo(name: '隐身大师', icon: 'fw_75', level: 2, description: '永久隐身，攻击显形，隐身状态下伤害减免'),
  RuneInfo(name: '如履平地', icon: 'fw_78', level: 2, description: '拥有穿越地形能力，生命值和生命恢复提升'),
  RuneInfo(name: '超级击退', icon: 'fw_80', level: 2, description: '每次攻击击退并额外造成神圣伤害'),
  RuneInfo(name: '真恩赐解脱', icon: 'fw_81', level: 2, description: '造成倍数伤害'),
  RuneInfo(name: '力量爆发', icon: 'fw_82', level: 2, description: '获得大量力量'),
  RuneInfo(name: '神盾镜', icon: 'fw_83', level: 2, description: '全属性提升，定期反弹指向性技能'),
  RuneInfo(name: '玻璃大炮', icon: 'fw_84', level: 2, description: '攻击力提升，无视目标护甲，但降低自身护甲和魔抗'),
  RuneInfo(name: '终极反弹', icon: 'fw_85', level: 2, description: '生命值提升，受到的伤害按比例反弹给目标'),
  RuneInfo(name: '倍镜', icon: 'fw_86', level: 2, description: '攻击距离提升，攻击间隔降低且不会丢失'),
  RuneInfo(name: '超级腐蚀', icon: 'fw_87', level: 2, description: '攻击提升，攻击降低目标护甲'),
  RuneInfo(name: '召唤大师', icon: 'fw_89', level: 2, description: '所有召唤物获得攻击力和攻速加成'),
  RuneInfo(name: '法术大师', icon: 'fw_91', level: 2, description: '施法距离和技能增强提升'),
  RuneInfo(name: '超级大板甲', icon: 'fw_93', level: 2, description: '护甲和生命恢复提升'),
  RuneInfo(name: '指向性大师', icon: 'fw_96', level: 2, description: '每次指向性技能额外造成主属性的魔法伤害'),
  RuneInfo(name: '肉体超强', icon: 'dotamd_100', level: 2, description: '每点力量额外提供生命值和生命回复'),
  RuneInfo(name: '质变随机', icon: 'dotamd_104', level: 2, description: '随机获得1个2级畸变符文'),
  RuneInfo(name: '虚假的无影拳', icon: 'fw_102', level: 2, description: '获得技能：虚假的无影拳'),
  RuneInfo(name: '虚假的风暴之锤', icon: 'fw_103', level: 2, description: '获得技能：虚假的风暴之锤'),
  RuneInfo(name: '虚假的掘地穿刺', icon: 'fw_104', level: 2, description: '获得技能：虚假的掘地穿刺'),
  RuneInfo(name: '虚假的静电链接', icon: 'fw_105', level: 2, description: '获得技能：虚假的静电链接'),
  RuneInfo(name: '践踏', icon: 'fw_106', level: 2, description: '获得技能：践踏'),
  RuneInfo(name: '虚假的传送', icon: 'fw_107', level: 2, description: '获得技能：虚假的传送'),
  RuneInfo(name: '虚假的蛛网', icon: 'fw_108', level: 2, description: '获得技能：虚假的蛛网'),
  RuneInfo(name: '超级质变', icon: 'dotamd_109', level: 2, description: '随机获得1个3级畸变符文'),
  RuneInfo(name: '虚假的狂暴', icon: 'fw_109', level: 2, description: '获得技能：虚假的狂暴'),
  RuneInfo(name: '虚假的剑刃风暴', icon: 'fw_111', level: 2, description: '获得技能：虚假的剑刃风暴'),
  RuneInfo(name: '虚假的强化图腾', icon: 'fw_112', level: 2, description: '获得技能：虚假的强化图腾'),
  RuneInfo(name: '坦克杀手', icon: 'fw_113', level: 2, description: '每次攻击对目标额外造成最大生命的物理伤害'),
  RuneInfo(name: '虚假的脉冲新星', icon: 'fw_114', level: 2, description: '获得技能：虚假的脉冲新星'),
  RuneInfo(name: '虚假的暗影之舞', icon: 'fw_115', level: 2, description: '获得技能：虚假的暗影之舞'),
  RuneInfo(name: '虚假的化学狂暴', icon: 'fw_116', level: 2, description: '获得技能：虚假的化学狂暴'),
  RuneInfo(name: '虚假的神之力量', icon: 'fw_118', level: 2, description: '获得技能：虚假的神之力量'),
  RuneInfo(name: '虚假的群蛇守卫', icon: 'fw_119', level: 2, description: '获得技能：虚假的群蛇守卫'),
  RuneInfo(name: '虚假的暗杀', icon: 'fw_120', level: 2, description: '获得技能：虚假的暗杀'),
  RuneInfo(name: '虚假的牺牲', icon: 'fw_121', level: 2, description: '获得技能：虚假的牺牲'),
  RuneInfo(name: '刷新', icon: 'fw_122', level: 2, description: '获得技能：刷新'),
  RuneInfo(name: '虚假的海象神拳', icon: 'fw_123', level: 2, description: '获得技能：虚假的海象神拳'),
  RuneInfo(name: '虚假的球状闪电', icon: 'fw_124', level: 2, description: '获得技能：虚假的球状闪电'),
  RuneInfo(name: '虚假的超新星', icon: 'fw_125', level: 2, description: '获得技能：虚假的超新星'),
  RuneInfo(name: '虚假的死神镰刀', icon: 'fw_126', level: 2, description: '获得技能：虚假的死神镰刀'),
  RuneInfo(name: '血之护盾', icon: 'fw_133', level: 2, description: '获得最大生命值的护盾，护盾不满时自动回复'),
  RuneInfo(name: '大吸一口', icon: 'fw_135', level: 2, description: '物理吸血，攻击力提升，低血量时数值翻倍'),
  RuneInfo(name: '智力爆发', icon: 'fw_137', level: 2, description: '获得大量智力'),
  RuneInfo(name: '敏捷爆发', icon: 'fw_138', level: 2, description: '获得大量敏捷'),
];
