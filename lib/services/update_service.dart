import 'dart:io';
import 'package:dio/dio.dart';

const _repo = 'fenli-forever/16dota';
const _baseUrl = 'https://github.com/$_repo/releases/latest/download';
const _versionUrl = '$_baseUrl/version.json';
const _androidDownloadUrl = '$_baseUrl/16dota-release.apk';
const _iosDownloadUrl = '$_baseUrl/16dota.ipa';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  static Future<UpdateInfo?> fetchLatest() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(_versionUrl);
      final data = res.data;
      if (data == null) return null;
      return UpdateInfo(
        version: data['version'] as String? ?? '',
        downloadUrl: Platform.isIOS ? _iosDownloadUrl : _androidDownloadUrl,
        releaseNotes: data['release_notes'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  // semver 比较：latest > current 返回 true
  static bool isNewer(String current, String latest) {
    final c = _parse(current);
    final l = _parse(latest);
    for (var i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String v) {
    final parts = v.replaceFirst(RegExp(r'^v'), '').split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }
}
