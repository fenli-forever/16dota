import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_service.dart';

class UpdateProvider extends ChangeNotifier {
  bool isChecking = false;
  bool isUpdateAvailable = false;
  String currentVersion = '';
  UpdateInfo? latestInfo;

  Future<void> checkForUpdate() async {
    if (isChecking) return;
    isChecking = true;
    notifyListeners();

    try {
      final info = await PackageInfo.fromPlatform();
      currentVersion = info.version;

      final latest = await UpdateService.fetchLatest();
      if (latest != null && UpdateService.isNewer(currentVersion, latest.version)) {
        latestInfo = latest;
        isUpdateAvailable = true;
      } else {
        latestInfo = latest;
        isUpdateAvailable = false;
      }
    } catch (_) {
      isUpdateAvailable = false;
    } finally {
      isChecking = false;
      notifyListeners();
    }
  }
}
