import 'package:flutter/foundation.dart';
import '../api/client.dart';
import '../models/match.dart';

class MatchProvider extends ChangeNotifier {
  final ApiClient api;
  MatchProvider(this.api);

  List<MatchRecord> _matches = [];
  bool _loading = false;
  bool _hasMore = true;
  int  _page = 1;
  String _error = '';

  List<MatchRecord> get matches => _matches;
  bool get loading  => _loading;
  bool get hasMore  => _hasMore;
  String get error  => _error;

  Future<void> load({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _page    = 1;
      _hasMore = true;
      _matches = [];
    }
    if (!_hasMore) return;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final raw = await api.matchHistory(page: _page, perPage: 20);
      final selfId  = api.userId;
      final newItems = raw
          .map((e) => MatchRecord.fromJson(
                e as Map<String, dynamic>,
                selfUserId: selfId,
              ))
          .toList();

      if (refresh) {
        _matches = newItems;
      } else {
        _matches.addAll(newItems);
      }

      _hasMore = newItems.length >= 20;
      _page++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
