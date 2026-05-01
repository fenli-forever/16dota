import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/update_provider.dart';

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
          const _SectionHeader('关于'),
          _VersionTile(
            version: update.currentVersion.isEmpty ? '…' : 'v${update.currentVersion}',
            hasUpdate: update.isUpdateAvailable,
          ),
          const _InfoTile(label: '游戏模式', value: '中路大乱斗'),
          const SizedBox(height: 8),
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
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.system_update_outlined, color: Color(0xFFE8A020), size: 22),
              const SizedBox(width: 8),
              Text(
                '发现新版本 v${info.version}',
                style: const TextStyle(
                    color: Color(0xFFCDD9E5), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (info.releaseNotes.isNotEmpty)
                Text(info.releaseNotes,
                    style: const TextStyle(
                        color: Color(0xFFCDD9E5), fontSize: 13, height: 1.5)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('暂不更新', style: TextStyle(color: Color(0xFF8B949E))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8A020)),
              onPressed: () async {
                Navigator.pop(ctx);
                final url = Uri.tryParse(info.downloadUrl);
                if (url != null) await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: const Text('立即更新',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

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
          title: Text(label,
              style: const TextStyle(color: Color(0xFFCDD9E5), fontSize: 14)),
          trailing: Text(value,
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
        ),
      );
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
