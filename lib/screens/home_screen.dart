import 'dart:io';
import 'package:dio/dio.dart';
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

class _UpdateDialog extends StatefulWidget {
  final String currentVersion;
  final UpdateInfo info;

  const _UpdateDialog({required this.currentVersion, required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double _progress = -1; // -1 = not started, 0.0~1.0 = downloading
  bool _failed = false;
  CancelToken? _cancelToken;

  bool get _isAndroid => Platform.isAndroid;
  bool get _downloading => _progress >= 0 && _progress < 1 && !_failed;

  void _startDownload() {
    setState(() {
      _progress = 0;
      _failed = false;
    });
    _cancelToken = CancelToken();
    UpdateService.downloadAndInstall(
      widget.info.downloadUrl,
      cancelToken: _cancelToken,
      onProgress: (p) => setState(() => _progress = p),
    ).then((path) {
      if (!mounted) return;
      if (path == null) {
        setState(() => _failed = true);
      }
      // If path != null, the APK installer was opened automatically
    });
  }

  void _fallbackToBrowser() async {
    final url = Uri.tryParse(widget.info.downloadUrl);
    if (url != null) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dialog closed');
    super.dispose();
  }

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
            '发现新版本 v${widget.info.version}',
            style: const TextStyle(color: Color(0xFFCDD9E5), fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _versionRow('当前版本', 'v${widget.currentVersion}'),
          const SizedBox(height: 4),
          _versionRow('最新版本', 'v${widget.info.version}', highlight: true),
          if (widget.info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('更新内容',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              widget.info.releaseNotes,
              style: const TextStyle(color: Color(0xFFCDD9E5), fontSize: 13, height: 1.5),
            ),
          ],
          if (_downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: const Color(0xFF21262D),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE8A020)),
            ),
            const SizedBox(height: 6),
            Text(
              _progress > 0 ? '下载中 ${(_progress * 100).toInt()}%' : '准备下载...',
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
            ),
          ],
          if (_failed) ...[
            const SizedBox(height: 12),
            const Text('自动下载失败，请手动下载',
                style: TextStyle(color: Color(0xFFF85149), fontSize: 12)),
          ],
        ],
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _failed ? '关闭' : '暂不更新',
              style: const TextStyle(color: Color(0xFF8B949E)),
            ),
          ),
        if (_downloading)
          TextButton(
            onPressed: () {
              _cancelToken?.cancel('user cancelled');
              setState(() {
                _progress = -1;
                _failed = false;
              });
            },
            child: const Text('取消下载', style: TextStyle(color: Color(0xFF8B949E))),
          ),
        if (!_downloading && !_failed)
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8A020)),
            onPressed: _isAndroid ? _startDownload : () {
              Navigator.pop(context);
              _fallbackToBrowser();
            },
            child: Text(
              _isAndroid ? '立即更新' : '前往下载',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        if (_failed)
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8A020)),
            onPressed: () {
              Navigator.pop(context);
              _fallbackToBrowser();
            },
            child: const Text('手动下载', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
