import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('好友', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, color: Color(0xFF8B949E), size: 64),
            SizedBox(height: 16),
            Text(
              '好友列表待接入',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '需要 Fiddler 抓包好友 API 后补充',
              style: TextStyle(color: Color(0xFF484F58), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
