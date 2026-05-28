import 'package:flutter/material.dart';
import 'rune_list_screen.dart';

/// Legacy entry point — redirects to [RuneListScreen].
class RuneIntroScreen extends StatelessWidget {
  const RuneIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Immediately replace this route with the new list screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RuneListScreen()),
        );
      }
    });
    return const Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFE8A020))),
    );
  }
}
