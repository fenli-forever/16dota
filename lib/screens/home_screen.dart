import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/update_provider.dart';
import '../services/update_service.dart';
import 'match_history_screen.dart';
import 'friends_screen.dart';
import 'ai_page.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  List<Widget> get _screens => [
    const MatchHistoryScreen(),
    const FriendsScreen(),
    if (Platform.isAndroid) const AiPage(),
    const ProfileScreen(),
  ];

  List<BottomNavigationBarItem> get _items => [
    const BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: '战绩',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people_outline),
      label: '好友',
    ),
    if (Platform.isAndroid)
      const BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome_outlined),
        activeIcon: Icon(Icons.auto_awesome),
        label: 'AI',
      ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: '我的',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdateProvider>().checkForUpdate().then((_) {
        if (mounted) _maybeShowUpdateDialog();
      });
    });
  }

  void _maybeShowUpdateDialog() {
    final update = context.read<UpdateProvider>();
    if (!update.isUpdateAvailable || update.latestInfo == null) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialog(
        currentVersion: update.currentVersion,
        info: update.latestInfo!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    final items = _items;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: const Color(0xFFE8A020),
        unselectedItemColor: const Color(0xFF484F58),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: items,
      ),
    );
  }
}

class _UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final UpdateInfo info;

  const _UpdateDialog({required this.currentVersion, required this.info});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.system_update_outlined, color: Color(0xFFE8A020), size: 22),
          const SizedBox(width: 8),
          Text(
            '发现新版本 v${info.version}',
            style: const TextStyle(color: Color(0xFFCDD9E5), fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _versionRow('当前版本', 'v$currentVersion'),
          const SizedBox(height: 4),
          _versionRow('最新版本', 'v${info.version}', highlight: true),
          if (info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('更新内容',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              info.releaseNotes,
              style: const TextStyle(color: Color(0xFFCDD9E5), fontSize: 13, height: 1.5),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('暂不更新', style: TextStyle(color: Color(0xFF8B949E))),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8A020)),
          onPressed: () async {
            Navigator.pop(context);
            final url = Uri.tryParse(info.downloadUrl);
            if (url != null) await launchUrl(url, mode: LaunchMode.externalApplication);
          },
          child: const Text('立即更新', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _versionRow(String label, String value, {bool highlight = false}) {
    return Row(
      children: [
        Text('$label：',
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
        Text(value,
            style: TextStyle(
              color: highlight ? const Color(0xFFE8A020) : const Color(0xFFCDD9E5),
              fontSize: 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            )),
      ],
    );
  }
}
