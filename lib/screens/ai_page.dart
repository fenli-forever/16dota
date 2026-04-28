import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../services/inference_service.dart';
import '../services/model_manager.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _AiPageState extends State<AiPage> {
  bool _modelInstalled = false;
  bool _checkingModel = true;
  double? _downloadProgress;

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
  }

  @override
  void dispose() {
    InferenceService.instance.removeListener(_onInferenceChanged);
    _chatSession?.close();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
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

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _chatBusy) return;
    final model = InferenceService.instance.model;
    if (model == null) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _chatBusy = true;
    });
    _scrollToBottom();

    try {
      _chatSession ??= await model.createSession(
          temperature: 0.7, topK: 40, randomSeed: 42);
      await _chatSession!.addQueryChunk(Message(text: text, isUser: true));
      final reply = (await _chatSession!.getResponse()).trim();
      if (mounted) {
        setState(() => _messages.add(_ChatMessage(text: reply, isUser: false)));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _messages.add(_ChatMessage(text: '生成失败：$e', isUser: false)));
      }
      await _chatSession?.close();
      _chatSession = null;
    } finally {
      if (mounted) setState(() => _chatBusy = false);
    }
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
              _buildStatusCard(),
              const Divider(height: 1, color: Color(0xFF21262D)),
              Expanded(child: _buildChatArea()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard() {
    final svc = InferenceService.instance;
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 16, color: Color(0xFF58A6FF)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Gemma 4 E4B 推理服务',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
              _InferenceStatusBadge(status: svc.status),
            ],
          ),
          const SizedBox(height: 10),
          if (_checkingModel)
            const SizedBox(
              height: 18,
              child: Row(children: [
                SizedBox(
                    width: 16,
                    height: 16,
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

  Widget _buildChatArea() {
    final isRunning =
        InferenceService.instance.status == InferenceStatus.running;

    if (!isRunning && _messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48,
                color: const Color(0xFF30363D)),
            const SizedBox(height: 12),
            const Text('启动推理服务后可开始对话',
                style: TextStyle(
                    color: Color(0xFF484F58), fontSize: 14)),
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
        _buildInputRow(isRunning),
      ],
    );
  }

  Widget _buildInputRow(bool isRunning) {
    final canSend = isRunning && !_chatBusy;
    return Container(
      color: const Color(0xFF161B22),
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: canSend,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: isRunning ? '发送消息…' : '推理服务未运行',
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
            onTap: canSend ? _sendMessage : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: canSend
                    ? const Color(0xFF58A6FF)
                    : const Color(0xFF21262D),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 18,
                color: canSend ? Colors.white : const Color(0xFF484F58),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

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
