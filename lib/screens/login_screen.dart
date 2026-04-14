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

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 11) return;
    setState(() => _sending = true);
    try {
      await context.read<AuthProvider>().sendSms(phone);
      setState(() => _codeSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败：$e')),
        );
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AuthProvider>().error)),
      );
      setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / 标题
              const Text(
                '16dota',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8A020),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '战绩查询',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 14),
              ),
              const SizedBox(height: 48),

              // 手机号
              _Field(
                controller: _phoneCtrl,
                hint: '手机号',
                keyboardType: TextInputType.phone,
                suffix: TextButton(
                  onPressed: _sending || _codeSent ? null : _sendCode,
                  child: _sending
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _codeSent ? '已发送' : '获取验证码',
                          style: const TextStyle(color: Color(0xFFE8A020)),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _logging
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black,
                        ),
                      )
                    : const Text('登录', style: TextStyle(fontSize: 16)),
              ),
            ],
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
        hintStyle: const TextStyle(color: Color(0xFF8B949E)),
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
