import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

const _repo = 'fenli-forever/16dota';
const _releasesApiUrl = 'https://api.github.com/repos/$_repo/releases/latest';
const _downloadBaseUrl = 'https://github.com/$_repo/releases/latest/download';

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
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/vnd.github+json'},
  ));

  static Future<UpdateInfo?> fetchLatest() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(_releasesApiUrl);
      final data = res.data;
      if (data == null) return null;

      final tagName = (data['tag_name'] as String?) ?? '';
      final body = (data['body'] as String?) ?? '';

      return UpdateInfo(
        version: tagName,
        downloadUrl: Platform.isIOS
            ? '$_downloadBaseUrl/16dota.ipa'
            : '$_downloadBaseUrl/16dota-release.apk',
        releaseNotes: body,
      );
    } catch (_) {
      return null;
    }
  }

  /// semver 比较：latest > current 返回 true
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
    final clean = v.replaceFirst(RegExp(r'^v'), '').replaceFirst(RegExp(r'\+.*'), '');
    final parts = clean.split('.');
    return List.generate(
        3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }

  /// Download APK and open for installation (Android only).
  /// Returns the file path on success, null on failure.
  /// [onProgress] receives 0.0~1.0 progress.
  static Future<String?> downloadAndInstall(
    String url, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (!Platform.isAndroid) return null;

    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/16dota-update.apk';

      await _dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      // Open the APK for installation
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type == ResultType.done) {
        return savePath;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> openDownloadPage(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
