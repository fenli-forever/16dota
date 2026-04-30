import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../services/external_ai_service.dart';
import '../services/inference_service.dart';
import '../services/model_manager.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

enum _AiMode { local, external }

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _AiPageState extends State<AiPage> {
  // ── local model state ──
  bool _modelInstalled = false;
  bool _checkingModel = true;
  double? _downloadProgress;

  // ── mode switch ──
  _AiMode _mode = _AiMode.local;

  // ── external config ──
  ExternalAiConfig _extConfig = ExternalAiConfig();
  final _baseUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _modelNameCtrl = TextEditingController();

  // ── chat state ──
  final List<_ChatMessage> _messages = [];
  InferenceModelSession? _chatSession;
  bool _chatBusy = false;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    InferenceService.instance.addListener(_onInferenceChanged);
    _checkModel();
    _loadExternalConfig();
  }

  @override
  void dispose() {
    InferenceService.instance.removeListener(_onInferenceChanged);
    _chatSession?.close();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelNameCtrl.dispose();
    super.dispose();
  }

  void _onInferenceChanged() {
    if (InferenceService.instance.status == InferenceStatus.stopped) {
      _chatSession?.close();
      if (mounted) setState(() { _chatSession = null; _chatBusy = false; });
    }
  }

  Future<void> _checkModel() async {
    final installed = await ModelManager.isInstalled();
    if (mounted) {
      setState(() { _modelInstalled = installed; _checkingModel = false; });
    }
  }

  Future<void> _loadExternalConfig() async {
    final config = await ExternalAiConfig.load();
    if (mounted) {
      setState(() {
        _extConfig = config;
        _baseUrlCtrl.text = config.baseUrl;
        _apiKeyCtrl.text = config.apiKey;
        _modelNameCtrl.text = config.model;
        if (config.isConfigured) _mode = _AiMode.external;
      });
    }
  }

  Future<void> _saveExternalConfig() async {
    _extConfig = ExternalAiConfig(
      baseUrl: _baseUrlCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim(),
      model: _modelNameCtrl.text.trim(),
    );
    await _extConfig.save();
    ExternalAiService.resetClient();
    if (mounted) {
      setState(() {});
      _snack('外部模型配置已保存');
    }
  }

  Future<void> _importFromLocal() async {
    setState(() => _checkingModel = true);
    try {
      final result = await ModelManager.importFromLocal();
      if (result == ImportResult.success && mounted) {
        setState(() => _modelInstalled = true);
      }
    } catch (e) {
      _snack('导入失败：$e');
    } finally {
      if (mounted) setState(() => _checkingModel = false);
    }
  }

  Future<void> _downloadFromNetwork() async {
    setState(() => _downloadProgress = 0);
    try {
      await ModelManager.downloadFromNetwork(
        onProgress: (pct) {
          if (mounted) setState(() => _downloadProgress = pct / 100.0);
        },
      );
      if (mounted) {
        setState(() { _modelInstalled = true; _downloadProgress = null; });
      }
    } catch (e) {
      if (mounted) setState(() => _downloadProgress = null);
      _snack('下载失败：$e');
    }
  }

  bool get _canSend {
    if (_chatBusy) return false;
    if (_mode == _AiMode.local) {
      return InferenceService.instance.status == InferenceStatus.running;
    }
    return _extConfig.isConfigured;
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || !_canSend) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _chatBusy = true;
    });
    _scrollToBottom();

    try {
      String reply;
      if (_mode == _AiMode.local) {
        reply = await _sendLocal(text);
      } else {
        reply = await _sendExternal(text);
      }
      if (mounted) {
        setState(() => _messages.add(_ChatMessage(text: reply, isUser: false)));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _messages.add(_ChatMessage(text: '生成失败：$e', isUser: false)));
      }
      if (_mode == _AiMode.local) {
        await _chatSession?.close();
        _chatSession = null;
      }
    } finally {
      if (mounted) setState(() => _chatBusy = false);
    }
  }

  Future<String> _sendLocal(String text) async {
    final model = InferenceService.instance.model;
    if (model == null) throw Exception('推理服务未运行');
    _chatSession ??= await model.createSession(
        temperature: 0.7, topK: 40, randomSeed: 42);
    await _chatSession!.addQueryChunk(Message(text: text, isUser: true));
    return (await _chatSession!.getResponse()).trim();
  }

  Future<String> _sendExternal(String text) async {
    // Build multi-turn message history
    final messages = <Map<String, String>>[];
    for (final msg in _messages) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }
    return ExternalAiService.chatMultiTurn(
      baseUrl: _extConfig.baseUrl,
      apiKey: _extConfig.apiKey,
      model: _extConfig.model,
      messages: messages,
    );
  }

  void _clearChat() {
    _chatSession?.close();
    setState(() { _chatSession = null; _messages.clear(); _chatBusy = false; });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF161B22),
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showSettingsSheet() {
    // Reload current config into text fields
    _baseUrlCtrl.text = _extConfig.baseUrl;
    _apiKeyCtrl.text = _extConfig.apiKey;
    _modelNameCtrl.text = _extConfig.model;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('外部模型配置',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('支持 OpenAI 兼容接口（如 DeepSeek、通义千问、Ollama 等）',
                    style: TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
                const SizedBox(height: 12),
                // Preset buttons
                Wrap(
                  spacing: 8,
                  children: [
                    _PresetChip(
                      label: 'DeepSeek',
                      onTap: () {
                        setSheetState(() {
                          _baseUrlCtrl.text = 'https://api.deepseek.com';
                          _modelNameCtrl.text = 'deepseek-chat';
                        });
                      },
                    ),
                    _PresetChip(
                      label: '通义千问',
                      onTap: () {
                        setSheetState(() {
                          _baseUrlCtrl.text = 'https://dashscope.aliyuncs.com/compatible-mode/v1';
                          _modelNameCtrl.text = 'qwen-plus';
                        });
                      },
                    ),
                    _PresetChip(
                      label: 'Ollama 本地',
                      onTap: () {
                        setSheetState(() {
                          _baseUrlCtrl.text = 'http://localhost:11434/v1';
                          _modelNameCtrl.text = 'qwen2.5:7b';
                          _apiKeyCtrl.text = 'ollama';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsField(
                  controller: _baseUrlCtrl,
                  label: 'Base URL',
                  hint: 'https://api.deepseek.com',
                  icon: Icons.link,
                ),
                const SizedBox(height: 12),
                _SettingsField(
                  controller: _apiKeyCtrl,
                  label: 'API Key',
                  hint: 'sk-...',
                  icon: Icons.key,
                  obscure: true,
                ),
                const SizedBox(height: 12),
                _SettingsField(
                  controller: _modelNameCtrl,
                  label: '模型名称',
                  hint: 'deepseek-chat',
                  icon: Icons.smart_toy_outlined,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final url = _baseUrlCtrl.text.trim();
                          final key = _apiKeyCtrl.text.trim();
                          final model = _modelNameCtrl.text.trim();
                          if (url.isEmpty || key.isEmpty || model.isEmpty) {
                            _snack('请填写完整配置');
                            return;
                          }
                          _snack('测试连接中…');
                          try {
                            await ExternalAiService.chat(
                              baseUrl: url,
                              apiKey: key,
                              model: model,
                              prompt: '你好',
                              maxTokens: 32,
                            );
                            _snack('连接成功');
                          } catch (e) {
                            _snack('连接失败：$e');
                          }
                        },
                        icon: const Icon(Icons.wifi_find, size: 14),
                        label: const Text('测试连接'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B949E),
                          side: const BorderSide(color: Color(0xFF30363D)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          _saveExternalConfig();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF58A6FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('保存配置',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(
          child: Text('AI 功能仅支持 Android',
              style: TextStyle(color: Color(0xFF8B949E))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text('AI',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Color(0xFF8B949E)),
            tooltip: '外部模型设置',
            onPressed: _showSettingsSheet,
          ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Color(0xFF8B949E)),
              tooltip: '清空对话',
              onPressed: _clearChat,
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: InferenceService.instance,
        builder: (context, _) {
          return Column(
            children: [
              _buildModeSwitcher(),
              if (_mode == _AiMode.local) _buildLocalStatusCard(),
              if (_mode == _AiMode.external) _buildExternalStatusCard(),
              const Divider(height: 1, color: Color(0xFF21262D)),
              Expanded(child: _buildChatArea()),
            ],
          );
        },
      ),
    );
  }

  // ── Mode switcher ────────────────────────────────────────────────────────

  Widget _buildModeSwitcher() {
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ModeTab(
            label: '本地模型',
            icon: Icons.phone_android,
            selected: _mode == _AiMode.local,
            onTap: () {
              if (_mode != _AiMode.local) {
                setState(() => _mode = _AiMode.local);
              }
            },
          ),
          const SizedBox(width: 8),
          _ModeTab(
            label: '外部模型',
            icon: Icons.cloud_outlined,
            selected: _mode == _AiMode.external,
            onTap: () {
              if (_mode != _AiMode.external) {
                _chatSession?.close();
                setState(() { _mode = _AiMode.external; _chatSession = null; });
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Local model status ──────────────────────────────────────────────────

  Widget _buildLocalStatusCard() {
    final svc = InferenceService.instance;
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 14, color: Color(0xFF58A6FF)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Gemma 4 E4B',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              _InferenceStatusBadge(status: svc.status),
            ],
          ),
          const SizedBox(height: 8),
          if (_checkingModel)
            const SizedBox(
              height: 18,
              child: Row(children: [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF58A6FF))),
                SizedBox(width: 8),
                Text('检查模型…',
                    style:
                        TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
              ]),
            )
          else if (!_modelInstalled)
            _buildInstallSection()
          else
            _buildInferenceButtons(svc),
          if (svc.status == InferenceStatus.error && svc.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(svc.errorMessage,
                style: const TextStyle(
                    color: Color(0xFFFF7B72), fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // ── External model status ────────────────────────────────────────────────

  Widget _buildExternalStatusCard() {
    final configured = _extConfig.isConfigured;
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(
            configured ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 14,
            color: configured ? const Color(0xFF2EA043) : const Color(0xFF484F58),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              configured
                  ? '${_extConfig.model} (${_extConfig.baseUrl.replaceFirst(RegExp(r'https?://'), '')})'
                  : '未配置外部模型',
              style: TextStyle(
                color: configured ? const Color(0xFFCDD9E5) : const Color(0xFF484F58),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _ActionBtn(
            icon: Icons.tune,
            label: configured ? '修改' : '配置',
            color: const Color(0xFF58A6FF),
            onTap: _showSettingsSheet,
          ),
        ],
      ),
    );
  }

  // ── Install / inference buttons ──────────────────────────────────────────

  Widget _buildInstallSection() {
    if (_downloadProgress != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '下载中 ${(_downloadProgress! * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: const Color(0xFF30363D),
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFF58A6FF)),
            minHeight: 4,
          ),
        ],
      );
    }
    return Row(
      children: [
        const Text('未安装模型',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
        const Spacer(),
        _ActionBtn(
          icon: Icons.folder_open,
          label: '本地导入',
          color: const Color(0xFF58A6FF),
          onTap: _importFromLocal,
        ),
        const SizedBox(width: 4),
        _ActionBtn(
          icon: Icons.cloud_download_outlined,
          label: '网络下载',
          color: const Color(0xFF58A6FF),
          onTap: _downloadFromNetwork,
        ),
      ],
    );
  }

  Widget _buildInferenceButtons(InferenceService svc) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'gemma-4-E4B-it.litertlm',
            style: TextStyle(color: Color(0xFF484F58), fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        switch (svc.status) {
          InferenceStatus.stopped || InferenceStatus.error => _ActionBtn(
              icon: Icons.play_arrow_rounded,
              label: '启动推理',
              color: const Color(0xFF2EA043),
              onTap: InferenceService.instance.start,
            ),
          InferenceStatus.starting => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF58A6FF)),
            ),
          InferenceStatus.running => _ActionBtn(
              icon: Icons.stop_rounded,
              label: '停止推理',
              color: const Color(0xFFDA3633),
              onTap: InferenceService.instance.stop,
            ),
        },
      ],
    );
  }

  // ── Chat area ───────────────────────────────────────────────────────────

  Widget _buildChatArea() {
    if (!_canSend && _messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48,
                color: const Color(0xFF30363D)),
            const SizedBox(height: 12),
            Text(
              _mode == _AiMode.local
                  ? '启动推理服务后可开始对话'
                  : '请先配置外部模型',
              style: const TextStyle(
                  color: Color(0xFF484F58), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Text('发送消息开始对话',
                      style: TextStyle(
                          color: Color(0xFF484F58), fontSize: 13)))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: _messages.length + (_chatBusy ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          child: _TypingIndicator(),
                        ),
                      );
                    }
                    return _MessageBubble(msg: _messages[i]);
                  },
                ),
        ),
        _buildInputRow(),
      ],
    );
  }

  Widget _buildInputRow() {
    return Container(
      color: const Color(0xFF161B22),
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: _canSend,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: _canSend ? '发送消息…' : (_mode == _AiMode.local ? '推理服务未运行' : '请先配置外部模型'),
                hintStyle: const TextStyle(
                    color: Color(0xFF484F58), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF0D1117),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      const BorderSide(color: Color(0xFF30363D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      const BorderSide(color: Color(0xFF30363D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      const BorderSide(color: Color(0xFF58A6FF)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      const BorderSide(color: Color(0xFF21262D)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _canSend ? _sendMessage : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _canSend
                    ? const Color(0xFF58A6FF)
                    : const Color(0xFF21262D),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 18,
                color: _canSend ? Colors.white : const Color(0xFF484F58),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF58A6FF) : const Color(0xFF484F58);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF58A6FF).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? const Color(0xFF58A6FF).withValues(alpha: 0.4)
                : const Color(0xFF30363D),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  const _SettingsField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8B949E), fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF30363D), fontSize: 13),
            prefixIcon: Icon(icon, size: 16, color: const Color(0xFF484F58)),
            filled: true,
            fillColor: const Color(0xFF0D1117),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF58A6FF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF58A6FF).withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Color(0xFF58A6FF),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _InferenceStatusBadge extends StatelessWidget {
  final InferenceStatus status;
  const _InferenceStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      InferenceStatus.stopped => ('已停止', const Color(0xFF484F58)),
      InferenceStatus.starting => ('启动中…', const Color(0xFFE8A020)),
      InferenceStatus.running => ('运行中', const Color(0xFF2EA043)),
      InferenceStatus.error => ('错误', const Color(0xFFDA3633)),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 6,
          height: 6,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color, fontSize: 11)),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        label:
            Text(label, style: TextStyle(fontSize: 12, color: color)),
        style: TextButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF58A6FF).withValues(alpha: 0.15)
              : const Color(0xFF161B22),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                Radius.circular(isUser ? 16 : 4),
            bottomRight:
                Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? const Color(0xFF58A6FF).withValues(alpha: 0.3)
                : const Color(0xFF30363D),
          ),
        ),
        child: SelectableText(
          msg.text,
          style: const TextStyle(
              color: Color(0xFFCDD9E5), fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF58A6FF)),
        ),
      );
}
