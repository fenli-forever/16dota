import 'package:flutter/material.dart';
import '../data/rune_data.dart';
import 'rune_detail_screen.dart';

class RuneListScreen extends StatefulWidget {
  const RuneListScreen({super.key});

  @override
  State<RuneListScreen> createState() => _RuneListScreenState();
}

class _RuneListScreenState extends State<RuneListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<RuneInfo> _filter(List<RuneInfo> runes) {
    if (_query.isEmpty) return runes;
    final q = _query.toLowerCase();
    return runes
        .where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q) ||
              r.category.toLowerCase().contains(q) ||
              r.stats.entries.any(
                (e) =>
                    e.key.toLowerCase().contains(q) ||
                    e.value.toLowerCase().contains(q),
              ),
        )
        .toList();
  }

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
        title: const Text(
          '符文介绍',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '搜索符文...',
                    hintStyle: const TextStyle(color: Color(0xFF484F58)),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF484F58),
                      size: 18,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF30363D)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF30363D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF58A6FF)),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tab,
                indicatorColor: const Color(0xFFE8A020),
                labelColor: const Color(0xFFE8A020),
                unselectedLabelColor: const Color(0xFF8B949E),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'MD装备 (${_filter(kMdRuneItems).length})'),
                  Tab(text: '1级符文 (${_filter(kLevel1Runes).length})'),
                  Tab(text: '2级符文 (${_filter(kLevel2Runes).length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildList(_filter(kMdRuneItems)),
          _buildList(_filter(kLevel1Runes)),
          _buildList(_filter(kLevel2Runes)),
        ],
      ),
    );
  }

  Widget _buildList(List<RuneInfo> runes) {
    if (runes.isEmpty) {
      return const Center(
        child: Text(
          '没有找到匹配的符文',
          style: TextStyle(color: Color(0xFF8B949E), fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: runes.length,
      itemBuilder: (_, i) => _RuneListTile(
        rune: runes[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RuneDetailScreen(rune: runes[i])),
        ),
      ),
    );
  }
}

class _RuneListTile extends StatelessWidget {
  final RuneInfo rune;
  final VoidCallback onTap;
  const _RuneListTile({required this.rune, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final levelColor = rune.level >= 2
        ? const Color(0xFFD8B4FE)
        : const Color(0xFF79C0FF);
    final levelBg = rune.level >= 2
        ? const Color(0xFF9B59B6).withValues(alpha: 0.3)
        : const Color(0xFF58A6FF).withValues(alpha: 0.2);
    final badgeText = rune.category.isNotEmpty
        ? rune.category
        : 'Lv.${rune.level}';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF21262D), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                rune.imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D444D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      rune.name.isNotEmpty ? rune.name[0] : '?',
                      style: const TextStyle(
                        color: Color(0xFFCDD9E5),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          rune.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: levelBg,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: levelColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (rune.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      rune.description,
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF484F58), size: 20),
          ],
        ),
      ),
    );
  }
}
