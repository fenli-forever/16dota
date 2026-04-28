import 'package:flutter/foundation.dart';
import '../api/client.dart';
import '../models/leaderboard.dart';

class LeaderboardProvider extends ChangeNotifier {
  final ApiClient api;
  LeaderboardProvider(this.api);

  List<Season> _seasons = [];
  Season? _selected;
  LeaderboardResult? _result;
  bool _loading = false;
  String _error = '';

  List<Season>        get seasons  => _seasons;
  Season?             get selected => _selected;
  LeaderboardResult?  get result   => _result;
  bool                get loading  => _loading;
  String              get error    => _error;

  Future<void> init() async {
    _loading = true;
    _error = '';
    notifyListeners();
    try {
      final data = await api.seasons();
      // API returns 'season_list' key (fallback to 'list')
      final rawList = ((data['season_list'] ?? data['list']) as List?)
              ?.cast<Map<String, dynamic>>() ?? [];
      final currentId = (data['current_activity_id'] as num?)?.toInt()
          ?? (data['activity_id'] as num?)?.toInt()
          ?? (rawList.isNotEmpty ? (rawList.first['activity_id'] as num?)?.toInt() ?? 0 : 0);

      _seasons = rawList
          .map((j) => Season.fromJson(j,
              isCurrent: (j['activity_id'] as num?)?.toInt() == currentId))
          .toList();

      if (_seasons.isEmpty && currentId > 0) {
        _seasons = [Season(activityId: currentId, name: '当前赛季', isCurrent: true)];
      }

      _selected = _seasons.firstWhere(
        (s) => s.isCurrent,
        orElse: () => _seasons.isNotEmpty ? _seasons.first : Season(activityId: 0, name: '', isCurrent: true),
      );

      if (_selected!.activityId > 0) {
        await _fetchLeaderboard();
      } else {
        _error = '未找到赛季数据';
        _loading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectSeason(Season s) async {
    if (_selected?.activityId == s.activityId) return;
    _selected = s;
    _result = null;
    notifyListeners();
    await _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    _loading = true;
    _error = '';
    notifyListeners();
    try {
      Map<String, dynamic> data = {};
      Object? lastError;
      for (final bt in ['MD', 'AP', 'TT', 'RD']) {
        try {
          data = await api.leaderboard(
              activityId: _selected!.activityId, subType: bt);
          if (data.isNotEmpty) break;
        } catch (e) {
          lastError = e;
        }
      }
      if (data.isEmpty && lastError != null) throw lastError;
      _result = LeaderboardResult.fromJson(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _fetchLeaderboard();
}
