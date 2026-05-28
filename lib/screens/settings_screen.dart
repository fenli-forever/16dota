import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/update_provider.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final update = context.watch<UpdateProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('设置',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _VersionTile(
            version: update.currentVersion.isEmpty ? '…' : 'v${update.currentVersion}',
            hasUpdate: update.isUpdateAvailable,
          ),
          const SizedBox(height: 1),
          _CheckUpdateTile(
            isChecking: update.isChecking,
            onTap: () => _checkUpdate(context),
          ),
        ],
      ),
    );
  }

  Future<void> _checkUpdate(BuildContext context) async {
    final update = context.read<UpdateProvider>();
    await update.checkForUpdate();
    if (!context.mounted) return;

    if (update.isUpdateAvailable && update.latestInfo != null) {
      final info = update.latestInfo!;
      final currentVersion = update.currentVersion;
      showDialog<void>(
        context: context,
        builder: (ctx) => _SettingsUpdateDialog(
          currentVersion: currentVersion,
          info: info,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已是最新版本'),
          backgroundColor: Color(0xFF161B22),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class _VersionTile extends StatelessWidget {
  final String version;
  final bool hasUpdate;
  const _VersionTile({required this.version, required this.hasUpdate});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: ListTile(
          dense: true,
          title: const Text('版本',
              style: TextStyle(color: Color(0xFFCDD9E5), fontSize: 14)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(version,
                  style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
              if (hasUpdate) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8534A),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _CheckUpdateTile extends StatelessWidget {
  final bool isChecking;
  final VoidCallback onTap;
  const _CheckUpdateTile({required this.isChecking, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: ListTile(
          dense: true,
          onTap: isChecking ? null : onTap,
          title: const Text('检查更新',
              style: TextStyle(color: Color(0xFFCDD9E5), fontSize: 14)),
          trailing: isChecking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFE8A020),
                  ),
                )
              : const Icon(Icons.chevron_right, color: Color(0xFF484F58), size: 20),
        ),
      );
}

class _SettingsUpdateDialog extends StatefulWidget {
  final String currentVersion;
  final UpdateInfo info;

  const _SettingsUpdateDialog({required this.currentVersion, required this.info});

  @override
  State<_SettingsUpdateDialog> createState() => _SettingsUpdateDialogState();
}

class _SettingsUpdateDialogState extends State<_SettingsUpdateDialog> {
  double _progress = -1;
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
      if (path == null) setState(() => _failed = true);
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
          if (widget.info.releaseNotes.isNotEmpty)
            Text(widget.info.releaseNotes,
                style: const TextStyle(color: Color(0xFFCDD9E5), fontSize: 13, height: 1.5)),
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
            child: Text(_failed ? '关闭' : '暂不更新',
                style: const TextStyle(color: Color(0xFF8B949E))),
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
            child: Text(_isAndroid ? '立即更新' : '前往下载',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        if (_failed)
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8A020)),
            onPressed: () {
              Navigator.pop(context);
              _fallbackToBrowser();
            },
            child: const Text('手动下载',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
