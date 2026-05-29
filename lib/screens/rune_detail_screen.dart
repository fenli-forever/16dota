import 'package:flutter/material.dart';
import '../data/rune_data.dart';
import '../widgets/rune_image.dart';

class RuneDetailScreen extends StatelessWidget {
  final RuneInfo rune;
  const RuneDetailScreen({super.key, required this.rune});

  @override
  Widget build(BuildContext context) {
    final levelColor = rune.level >= 2
        ? const Color(0xFFD8B4FE)
        : const Color(0xFF79C0FF);
    final levelBg = rune.level >= 2
        ? const Color(0xFF9B59B6).withValues(alpha: 0.3)
        : const Color(0xFF58A6FF).withValues(alpha: 0.2);

    final sameLevel = rune.category == 'MD初始装备'
        ? kMdRuneItems
        : rune.level >= 2
        ? kLevel2Runes
        : kLevel1Runes;
    final badgeText = rune.category.isNotEmpty
        ? rune.category
        : rune.level >= 2
        ? '2级符文（畸变）'
        : '1级符文';
    final sectionTitle = rune.category == 'MD初始装备'
        ? '全部MD初始装备'
        : '全部${rune.level}级符文';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '符文详情',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── Hero section ──
          Container(
            color: const Color(0xFF161B22),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                RuneImage(
                  imageUrl: rune.imageUrl,
                  assetPath: rune.assetPath,
                  fallbackText: rune.name,
                  size: 72,
                  borderRadius: 8,
                  fallbackFontSize: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rune.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: levelBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: levelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (rune.stats.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rune.stats.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.value,
                          style: const TextStyle(
                            color: Color(0xFFE8A020),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Description ──
          if (rune.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '效果说明',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rune.description,
                    style: const TextStyle(
                      color: Color(0xFFCDD9E5),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Same level runes ──
          Container(
            color: const Color(0xFF161B22),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  color: levelColor,
                  margin: const EdgeInsets.only(right: 8),
                ),
                Text(
                  sectionTitle,
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${sameLevel.length}个',
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Grid of same-level runes
          Container(
            color: const Color(0xFF161B22),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sameLevel.map((r) {
                final isCurrent = r.icon == rune.icon;
                return GestureDetector(
                  onTap: isCurrent
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RuneDetailScreen(rune: r),
                            ),
                          );
                        },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFFE8A020).withValues(alpha: 0.15)
                          : const Color(0xFF2D3139),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFFE8A020)
                            : const Color(0xFF444C56),
                        width: isCurrent ? 1.5 : 0.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: RuneImage(
                        imageUrl: r.imageUrl,
                        assetPath: r.assetPath,
                        fallbackText: r.name,
                        size: 48,
                        borderRadius: 5,
                        fallbackFontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
