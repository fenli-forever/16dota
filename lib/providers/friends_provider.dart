import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendEntry {
  final String userId;
  final String nickname;
  final String avatar;
  final String rankName;

  const FriendEntry({
    required this.userId,
    required this.nickname,
    this.avatar   = '',
    this.rankName = '',
  });

  Map<String, dynamic> toJson() => {
    'userId':   userId,
    'nickname': nickname,
    'avatar':   avatar,
    'rankName': rankName,
  };

  factory FriendEntry.fromJson(Map<String, dynamic> j) => FriendEntry(
    userId:   j['userId']?.toString()   ?? '',
    nickname: j['nickname']?.toString() ?? '',
    avatar:   j['avatar']?.toString()   ?? '',
    rankName: j['rankName']?.toString() ?? '',
  );
}

class FriendsProvider extends ChangeNotifier {
  static const _key = 'saved_friends';
  List<FriendEntry> _friends = [];

  List<FriendEntry> get friends => _friends;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _friends = list.map(FriendEntry.fromJson).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addFriend(FriendEntry friend) async {
    if (_friends.any((f) => f.userId == friend.userId)) return;
    _friends = [..._friends, friend];
    await _save();
    notifyListeners();
  }

  Future<void> removeFriend(String userId) async {
    _friends = _friends.where((f) => f.userId != userId).toList();
    await _save();
    notifyListeners();
  }

  bool isFriend(String userId) => _friends.any((f) => f.userId == userId);

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_friends.map((f) => f.toJson()).toList()));
  }
}
