import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mall4jApi   = 'https://mall4j-api.16dota.com.cn';
const _rustwarApi  = 'https://rustwar.16dota.com.cn';
const _teamupApi   = 'https://teamup.16dota.com.cn';
const _ladderApi   = 'https://leaderboard.16dota.com.cn';

// ── API Client ─────────────────────────────────────────────────────────
class ApiClient {
  late final Dio _dio;
  String _accessToken = '';
  String _deviceId    = '';
  String _userId      = '';

  ApiClient() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
        'User-Agent':   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                        'AppleWebKit/537.36 (KHTML, like Gecko) '
                        'Chrome/109.0.0.0 Safari/537.36',
        'Appversion':   '1.5.0|web=1.0.9;worker=0.0.0.2026032601',
      },
    ));
  }

  // ── 初始化：从本地存储恢复 token ─────────────────────────────────────
  Future<bool> init() async {
    final prefs  = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken') ?? '';
    _userId      = prefs.getString('userId')      ?? '';
    _deviceId    = prefs.getString('deviceId')    ?? _generateDeviceId();
    await prefs.setString('deviceId', _deviceId);
    return _accessToken.isNotEmpty;
  }

  bool   get isLoggedIn => _accessToken.isNotEmpty;
  String get userId     => _userId;

  String _generateDeviceId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return md5.convert(utf8.encode(ts)).toString();
  }

  // ── 登录相关 ──────────────────────────────────────────────────────────

  /// 发送手机验证码（PUT）
  Future<void> sendSmsCode(String phone) async {
    await _dio.put(
      '$_mall4jApi/sendRegisterOrLoginSms',
      data: {'mobile': phone},
      options: Options(headers: _appHeaders()),
    );
  }

  /// 验证码登录
  Future<Map<String, dynamic>> loginBySms(String phone, String code) async {
    final resp = await _dio.post(
      '$_mall4jApi/smsRegisterAndLogin',
      data: {'userName': phone, 'passWord': code},
      options: Options(headers: _appHeaders()),
    );
    await _saveToken(resp.data as Map<String, dynamic>);
    return resp.data as Map<String, dynamic>;
  }

  /// 刷新 token
  Future<bool> refreshToken() async {
    final prefs      = await SharedPreferences.getInstance();
    final refreshTok = prefs.getString('refreshToken') ?? '';
    if (refreshTok.isEmpty) return false;
    try {
      final resp = await _dio.post(
        '$_mall4jApi/token/loginByRefreshToken',
        data: {'refreshToken': refreshTok},
        options: Options(headers: _appHeaders()),
      );
      await _saveToken(resp.data as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    _accessToken = '';
    _userId      = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
  }

  // ── 玩家信息 ──────────────────────────────────────────────────────────

  /// POST /api/user/userinfo → data.player_info
  Future<Map<String, dynamic>> playerInfo() async {
    final resp = await _authedReq('POST', '$_rustwarApi/api/user/userinfo', {});
    return resp['data'] as Map<String, dynamic>;
  }

  // ── 战绩 ──────────────────────────────────────────────────────────────

  /// GET /api/teamup/{userId}/match_history?per_page=N&page=N&is_valid=true
  Future<List<dynamic>> matchHistory({int page = 1, int perPage = 20}) async {
    final url = '$_rustwarApi/api/teamup/$_userId/match_history'
        '?per_page=$perPage&page=$page&is_valid=true';
    final resp = await _authedReq('GET', url, null);
    return resp['data'] as List? ?? [];
  }

  /// POST teamup.../api/teamup/game_info/settlement
  Future<Map<String, dynamic>> settlement(String gameId) async {
    final resp = await _authedReq(
      'POST', '$_teamupApi/api/teamup/game_info/settlement',
      {'game_id': gameId},
    );
    return resp['data'] as Map<String, dynamic>? ?? {};
  }

  // ── 天梯 ──────────────────────────────────────────────────────────────

  /// POST leaderboard.../api/leaderboard/super_dota/record
  Future<Map<String, dynamic>> leaderboard({
    required int activityId,
    String subType = 'MD',
  }) async {
    final resp = await _authedReq(
      'POST', '$_ladderApi/api/leaderboard/super_dota/record',
      {'activity_id': activityId, 'sub_type': subType, 'user_id': _userId},
    );
    return resp['data'] as Map<String, dynamic>? ?? {};
  }

  /// POST /api/seasons/list — 获取赛季列表（用于拿 activity_id）
  Future<Map<String, dynamic>> seasons() async {
    final resp = await _authedReq('POST', '$_rustwarApi/api/seasons/list', {});
    return resp['data'] as Map<String, dynamic>? ?? {};
  }

  // ── 好友（占位，待抓包后补充）────────────────────────────────────────

  Future<List<dynamic>> friendList() async {
    // TODO: 抓包后补充真实端点
    return [];
  }

  // ── 内部工具 ──────────────────────────────────────────────────────────

  Map<String, String> _appHeaders() => {
    'appVersion':      '1.5.0',
    'deviceId':        _deviceId,
    'machineUniqueId': _deviceId,
  };

  Future<Map<String, dynamic>> _authedReq(
    String method,
    String url,
    Map<String, dynamic>? body,
  ) async {
    final opts = Options(
      method: method,
      headers: {
        ..._appHeaders(),
        'Authorization': _accessToken,
        'Cookie':        'Authorization=$_accessToken',
      },
    );
    try {
      final resp = await _dio.request(url, data: body, options: opts);
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final ok = await refreshToken();
        if (ok) return _authedReq(method, url, body);
      }
      rethrow;
    }
  }

  Future<void> _saveToken(Map<String, dynamic> data) async {
    _accessToken = data['accessToken'] as String? ?? '';
    _userId      = data['userId']      as String? ?? '';
    final prefs  = await SharedPreferences.getInstance();
    await prefs.setString('accessToken',  _accessToken);
    await prefs.setString('refreshToken', data['refreshToken'] as String? ?? '');
    await prefs.setString('userId',       _userId);
  }
}
