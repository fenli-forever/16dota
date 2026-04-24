import 'package:flutter/foundation.dart';
import '../api/client.dart';
import '../models/match.dart';

enum AuthState { unknown, loggedOut, loggedIn }

class AuthProvider extends ChangeNotifier {
  final ApiClient api = ApiClient();

  AuthState _state = AuthState.unknown;
  PlayerProfile? _profile;
  String _error = '';

  AuthState get state   => _state;
  PlayerProfile? get profile => _profile;
  String get error      => _error;
  bool get isLoggedIn   => _state == AuthState.loggedIn;

  Future<void> init() async {
    final hasToken = await api.init();
    if (!hasToken) {
      _state = AuthState.loggedOut;
      notifyListeners();
      return;
    }
    await _loadProfile();
  }

  Future<void> sendSms(String phone) async {
    await api.sendSmsCode(phone);
  }

  Future<bool> loginBySms(String phone, String code) async {
    try {
      _error = '';
      await api.loginBySms(phone, code);
      await _loadProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() => _loadProfile();

  Future<void> logout() async {
    await api.logout();
    _profile = null;
    _state = AuthState.loggedOut;
    notifyListeners();
  }

  // 记录各接口数据，供 UI 调试展示
  Map<String, dynamic> lastRustData   = {};
  Map<String, dynamic> lastMallData   = {};
  Map<String, dynamic> lastLadderData = {};
  String profileLoadError = '';

  Future<void> _loadProfile() async {
    try {
      profileLoadError = '';

      // 1. rustwar userinfo → player_info.id / name / extid
      lastRustData = await api.playerInfo();

      // 2. mall4j userInfo → nickName / pic
      lastMallData = await api.mallUserInfo()
          .catchError((_) => <String, dynamic>{});

      // 3. 当前赛季天梯 → rank_name / rank_points / mmr / win/lose
      //    依次尝试多种 battle_type，取第一个非空结果
      lastLadderData = {};
      try {
        final seasons    = await api.seasons();
        final seasonList = ((seasons['season_list'] ?? seasons['list']) as List?)
                ?.cast<Map<String, dynamic>>() ?? [];
        if (seasonList.isNotEmpty) {
          final actId = (seasonList.first['activity_id'] as num).toInt();
          for (final bt in ['AP', 'MD', 'RD', 'OMG']) {
            final d = await api.leaderboard(activityId: actId, battleType: bt)
                .catchError((_) => <String, dynamic>{});
            if (d.isNotEmpty && d['rank_name'] != null) {
              lastLadderData = d;
              break;
            }
          }
        }
      } catch (e) {
        profileLoadError = '天梯数据加载失败: $e';
      }

      _profile = PlayerProfile.fromMerged(
          lastRustData, lastMallData, lastLadderData);
      _state   = AuthState.loggedIn;
    } catch (e) {
      profileLoadError = e.toString();
      _state = AuthState.loggedOut;
    }
    notifyListeners();
  }
}
