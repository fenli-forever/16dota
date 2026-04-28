import 'dart:io';
import 'package:flutter/material.dart';
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
