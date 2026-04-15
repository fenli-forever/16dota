import 'package:flutter/material.dart';
import 'match_history_screen.dart';
import 'leaderboard_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final _screens = const [
    MatchHistoryScreen(),
    LeaderboardScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: const Color(0xFFE8A020),
        unselectedItemColor: const Color(0xFF484F58),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '战绩',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: '天梯',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
