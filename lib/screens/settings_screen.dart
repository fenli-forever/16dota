import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../services/ai_summary_service.dart';
import '../services/model_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _modelInstalled = false;
  bool _modelLoaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!Platform.isAndroid) return;
    final installed = await ModelManager.isInstalled();
    setState(() {
      _modelInstalled = installed;
      _modelLoaded = AiSummaryService.isModelLoaded;
    });
  }

  Future<void> _closeModel() async {
    setState(() => _busy = true);
    await AiSummaryService.closeModel();
    setState(() { _busy = false; _modelLoaded = false; });
    _snack('AI 模型已从内存中卸载');
  }

  Future<void> _deleteModel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('删除模型文件',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          '将从设备存储中删除模型文件（约 1.7 GB），\n下次使用需重新导入或下载。',
          style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF8B949E))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFDA3633))),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    await AiSummaryService.closeModel();
    await FlutterGemma.uninstallModel(ModelManager.installedModelId);
    await _refresh();
    setState(() => _busy = false);
    _snack('模型文件已删除');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF161B22),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        title: const Text('设置',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (Platform.isAndroid) ...[
            _SectionHeader('AI 智能总结'),
            _AiModelCard(
              installed: _modelInstalled,
              loaded: _modelLoaded,
              busy: _busy,
              onClose: _modelLoaded ? _closeModel : null,
              onDelete: _modelInstalled ? _deleteModel : null,
            ),
            const SizedBox(height: 24),
          ],
          _SectionHeader('关于'),
          _InfoTile(label: '版本', value: 'v0.1.7'),
          _InfoTile(label: '游戏模式', value: '中路大乱斗'),
        ],
      ),
    );
  }
}

// ── AI 模型状态卡片 ────────────────────────────────────────────────────────

class _AiModelCard extends StatelessWidget {
  final bool installed;
  final bool loaded;
  final bool busy;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  const _AiModelCard({
    required this.installed,
    required this.loaded,
    required this.busy,
    this.onClose,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          // 状态行
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF58A6FF), size: 18),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gemma 4 E4B 模型',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  _StatusBadge(installed: installed, loaded: loaded),
                ],
              ),
              if (busy) ...[
                const Spacer(),
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF58A6FF)),
                ),
              ],
            ]),
          ),
          // 操作按钮
          if (installed) ...[
            const Divider(color: Color(0xFF30363D), height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(children: [
                if (onClose != null)
                  _ActionButton(
                    icon: Icons.memory,
                    label: '从内存卸载',
                    color: const Color(0xFFE8A020),
                    onTap: busy ? null : onClose,
                  ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: '删除文件',
                    color: const Color(0xFFDA3633),
                    onTap: busy ? null : onDelete,
                  ),
                ],
              ]),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: const Text(
                '未安装模型。在对战详情页点击「AI智能总结」可导入模型文件。',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool installed;
  final bool loaded;
  const _StatusBadge({required this.installed, required this.loaded});

  @override
  Widget build(BuildContext context) {
    final (label, color) = !installed
        ? ('未安装', const Color(0xFF484F58))
        : loaded
            ? ('已加载到内存', const Color(0xFF2EA043))
            : ('已安装，未加载', const Color(0xFF8B949E));

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color, fontSize: 11)),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 14, color: onTap == null ? const Color(0xFF484F58) : color),
    label: Text(label,
        style: TextStyle(
            fontSize: 12,
            color: onTap == null ? const Color(0xFF484F58) : color)),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
  );
}

// ── 通用组件 ───────────────────────────────────────────────────────────────

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
