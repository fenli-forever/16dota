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

  Future<void> _loadProfile() async {
    try {
      final data = await api.playerInfo();
      _profile = PlayerProfile.fromJson(data);
      _state = AuthState.loggedIn;
    } catch (e) {
      _state = AuthState.loggedOut;
    }
    notifyListeners();
  }
}
