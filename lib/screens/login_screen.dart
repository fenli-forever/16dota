import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl  = TextEditingController();
  bool _codeSent   = false;
  bool _sending    = false;
  bool _logging    = false;
  int  _countdown  = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          t.cancel();
          _codeSent = false;
        }
      });
    });
  }

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 11) {
      _showSnack('请输入正确的手机号');
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<AuthProvider>().sendSms(phone);
      setState(() { _codeSent = true; });
      _startCountdown();
      _showSnack('验证码已发送');
    } catch (e) {
      _showSnack('发送失败：$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _login() async {
    final phone = _phoneCtrl.text.trim();
    final code  = _codeCtrl.text.trim();
    if (phone.isEmpty || code.isEmpty) return;
    setState(() => _logging = true);
    final ok = await context.read<AuthProvider>().loginBySms(phone, code);
    if (mounted && !ok) {
      _showSnack(context.read<AuthProvider>().error);
      setState(() => _logging = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF161B22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !_sending && !_codeSent;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // App 图标
                Center(
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.shield,
                      size: 80,
                      color: Color(0xFFE8A020),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 标题
                const Text(
                  '16dota',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE8A020),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '战绩查询 · 天梯榜',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                ),
                const SizedBox(height: 48),

                // 手机号
                _Field(
                  controller: _phoneCtrl,
                  hint: '手机号',
                  keyboardType: TextInputType.phone,
                  suffix: TextButton(
                    onPressed: canSend ? _sendCode : null,
                    child: _sending
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE8A020)),
                          )
                        : Text(
                            _countdown > 0
                                ? '${_countdown}s'
                                : '获取验证码',
                            style: TextStyle(
                              color: canSend
                                  ? const Color(0xFFE8A020)
                                  : const Color(0xFF484F58),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // 验证码
                _Field(
                  controller: _codeCtrl,
                  hint: '验证码',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),

                // 登录按钮
                ElevatedButton(
                  onPressed: _logging ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8A020),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        const Color(0xFFE8A020).withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _logging
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('登录',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Widget? suffix;
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF484F58)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF161B22),
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
          borderSide: const BorderSide(color: Color(0xFFE8A020)),
        ),
      ),
    );
  }
}
